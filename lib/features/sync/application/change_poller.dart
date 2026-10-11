import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/change_repository.dart';

/// Erzeugt einen einmaligen Timer; in Tests durch eine Fake-Variante ersetzbar.
typedef PollTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// Aufruf des Owners, der alle betroffenen Daten still neu lädt. Liefert nur
/// `true`, wenn wirklich alle angeforderten Loads erfolgreich waren.
typedef SilentRefresh = Future<bool> Function();

/// Fragt GET /api/changes periodisch ab und löst bei `refresh_required` einen
/// stillen Refresh aus.
///
/// Garantien:
/// * Höchstens ein Request gleichzeitig und höchstens ein geplanter Timer.
/// * Der opake Cursor wird nur übernommen, wenn der Refresh vollständig
///   erfolgreich war; sonst wird beim nächsten Versuch derselbe Cursor erneut
///   gesendet, sodass keine Änderung verloren geht.
/// * Fehler werden mit begrenztem Backoff wiederholt und als [errorMessage]
///   veröffentlicht, statt verschluckt zu werden.
class ChangePoller extends ChangeNotifier {
  ChangePoller({
    required this.repository,
    required this.onRefreshRequired,
    this.interval = const Duration(seconds: 5),
    this.maxBackoff = const Duration(seconds: 60),
    this.requestTimeout = const Duration(seconds: 15),
    PollTimerFactory? timerFactory,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final ChangeRepositoryContract repository;
  final SilentRefresh onRefreshRequired;
  final PollTimerFactory _timerFactory;
  final Duration interval;
  final Duration maxBackoff;

  /// Obergrenze für einen einzelnen Feed-Request. Verhindert, dass ein
  /// hängender Request das Polling (oder den Initial-Load) dauerhaft blockiert.
  final Duration requestTimeout;

  String? _cursor;
  bool _refreshPending = false;
  bool _active = false;
  bool _stopped = false;
  bool _disposed = false;
  bool _unauthorized = false;
  Timer? _timer;
  Timer? _timeoutTimer;
  Future<void>? _inFlight;
  int _consecutiveFailures = 0;
  String? _errorMessage;
  Object? _lastError;

  /// Ob aktuell ein Cursor vorliegt (der Inhalt bleibt bewusst privat).
  bool get hasBaseline => _cursor != null;
  bool get isActive => _active;
  bool get isRequestInFlight => _inFlight != null;
  bool get isUnauthorized => _unauthorized;
  bool get isTimerScheduled => _timer?.isActive ?? false;
  int get consecutiveFailures => _consecutiveFailures;
  String? get errorMessage => _errorMessage;
  Object? get lastError => _lastError;

  /// Verzögerung bis zum nächsten Versuch: Normalintervall bzw. exponentieller,
  /// durch [maxBackoff] begrenzter Backoff nach Fehlern.
  Duration get nextDelay {
    if (_consecutiveFailures == 0) return interval;
    final factor = 1 << math.min(_consecutiveFailures, 10);
    final delay = interval * factor;
    return delay > maxBackoff ? maxBackoff : delay;
  }

  /// Holt die Baseline vor dem initialen Full Load. Schlägt das fehl, wird
  /// beim nächsten Poll eine neue Baseline geholt und danach still neu
  /// geladen, damit Änderungen während des Initial-Loads nicht verloren gehen.
  Future<bool> establishBaseline() async {
    if (_disposed || _stopped) return false;
    await _exclusive(() => _cycle(allowRefresh: false));
    return _cursor != null && _errorMessage == null;
  }

  /// Erzwingt beim nächsten Poll einen Refresh, auch wenn das Backend keine
  /// Änderung meldet (z.B. nach fehlgeschlagenem Initial-Load).
  void markRefreshRequired() {
    if (_disposed) return;
    _refreshPending = true;
  }

  /// Aktiviert das Polling und wartet zunächst das reguläre Intervall ab.
  void start() {
    if (_disposed || _stopped || _unauthorized) return;
    _active = true;
    _schedule();
  }

  /// Aktiviert das Polling und fragt sofort ab (z.B. beim App-Resume).
  void resume() {
    if (_disposed || _stopped || _unauthorized) return;
    _active = true;
    unawaited(pollNow());
  }

  /// Pausiert ohne Zustand zu verwerfen; ein laufender Request wird zu Ende
  /// verarbeitet, plant danach aber keinen neuen Timer.
  void pause() {
    _active = false;
    _cancelTimer();
  }

  /// Endgültig beenden (Logout). Danach startet das Polling nicht mehr.
  void stop() {
    _stopped = true;
    pause();
  }

  /// Sofortige Abfrage, falls nicht bereits ein Request läuft.
  Future<void> pollNow() {
    if (_disposed || _stopped) return Future.value();
    if (_unauthorized) return Future.value();
    _cancelTimer();
    return _exclusive(() => _cycle(allowRefresh: true));
  }

  Future<void> _exclusive(Future<void> Function() action) {
    final running = _inFlight;
    if (running != null) return running;
    final future = action().whenComplete(() {
      _inFlight = null;
      _schedule();
    });
    _inFlight = future;
    return future;
  }

  Future<void> _cycle({required bool allowRefresh}) async {
    final hadBaseline = _cursor != null;
    try {
      final feed = await _withTimeout(repository.fetchChanges(after: _cursor));
      if (_disposed || _stopped) return;
      // Eine Baseline, die erst nach den angezeigten Daten geholt wurde,
      // deckt den Zeitraum davor nicht ab und erzwingt deshalb einen Refresh.
      final needsRefresh =
          allowRefresh &&
          (feed.refreshRequired || _refreshPending || !hadBaseline);
      if (needsRefresh) {
        final ok = await onRefreshRequired();
        if (_disposed || _stopped) return;
        if (!ok) {
          _refreshPending = true;
          _fail(
            StateError('Stiller Refresh fehlgeschlagen'),
            'Daten konnten nicht automatisch aktualisiert werden.',
          );
          return;
        }
        _refreshPending = false;
      }
      _cursor = feed.nextCursor;
      _succeed();
    } catch (error) {
      if (_disposed || _stopped) return;
      if (!hadBaseline && !allowRefresh) _refreshPending = true;
      if (error is ApiException &&
          error.statusCode == 400 &&
          hadBaseline &&
          allowRefresh) {
        // Ungültiger Cursor (z.B. nach Secret-Rotation): verwerfen, sofort
        // eine neue Baseline holen und erst DANACH still neu laden. Der neue
        // Cursor wird nur nach erfolgreichem Refresh übernommen; scheitert er,
        // bleibt der Cursor leer und der nächste Versuch beginnt wieder mit
        // einer frischen Baseline, sodass keine Änderung verloren geht.
        debugPrint('ChangePoller: Cursor ungültig, neue Baseline ($error)');
        _cursor = null;
        _refreshPending = true;
        await _cycle(allowRefresh: true);
        return;
      }
      if (error is ApiException && error.statusCode == 401) {
        // Abgelaufenes/ungültiges JWT: nicht wiederholen, Polling beenden.
        _unauthorized = true;
        _active = false;
        _fail(error, 'Sitzung abgelaufen. Bitte erneut anmelden.');
        return;
      }
      _fail(
        error,
        error is ApiException
            ? 'Automatische Aktualisierung fehlgeschlagen: ${error.message}'
            : 'Automatische Aktualisierung derzeit nicht möglich.',
      );
    }
  }

  /// Timeout über die injizierte Timer-Factory, damit Tests ohne echte Timer
  /// auskommen und dispose() den Timer zuverlässig aufräumt.
  Future<T> _withTimeout<T>(Future<T> future) {
    final completer = Completer<T>();
    _timeoutTimer?.cancel();
    final timer = _timerFactory(requestTimeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Änderungs-Feed antwortet nicht', requestTimeout),
        );
      }
    });
    _timeoutTimer = timer;
    future.then(
      (value) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        timer.cancel();
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );
    return completer.future;
  }

  void _succeed() {
    final changed = _errorMessage != null || _consecutiveFailures != 0;
    _consecutiveFailures = 0;
    _errorMessage = null;
    _lastError = null;
    if (changed) notifyListeners();
  }

  void _fail(Object error, String message) {
    _consecutiveFailures++;
    _lastError = error;
    _errorMessage = message;
    debugPrint('ChangePoller: $error');
    notifyListeners();
  }

  void _schedule() {
    _cancelTimer();
    if (!_active || _disposed || _stopped || _unauthorized) return;
    if (_inFlight != null) return;
    _timer = _timerFactory(nextDelay, () {
      _timer = null;
      unawaited(pollNow());
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _cancelTimer();
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    super.dispose();
  }
}
