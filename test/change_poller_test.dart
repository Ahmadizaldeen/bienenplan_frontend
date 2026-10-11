import 'dart:async';

import 'package:bienenplan_frontend/core/api/api_exception.dart';
import 'package:bienenplan_frontend/features/sync/application/change_poller.dart';
import 'package:bienenplan_frontend/features/sync/data/change_feed.dart';
import 'package:bienenplan_frontend/features/sync/data/change_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _interval = Duration(seconds: 5);
const _timeout = Duration(seconds: 99);

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

class _Timers {
  final created = <_FakeTimer>[];

  Timer call(Duration delay, void Function() callback) {
    final timer = _FakeTimer(delay, callback);
    created.add(timer);
    return timer;
  }

  /// Aktive Poll-Timer (ohne Request-Timeouts).
  List<_FakeTimer> get polls =>
      created.where((t) => t.isActive && t.duration != _timeout).toList();

  List<_FakeTimer> get timeouts =>
      created.where((t) => t.isActive && t.duration == _timeout).toList();
}

class _Feed implements ChangeRepositoryContract {
  final afters = <String?>[];
  final responses = <Object>[];
  Completer<ChangeFeed>? hold;

  @override
  Future<ChangeFeed> fetchChanges({String? after}) {
    afters.add(after);
    final held = hold;
    if (held != null) return held.future;
    final response = responses.removeAt(0);
    if (response is ChangeFeed) return Future.value(response);
    return Future.error(response);
  }
}

ChangeFeed _feed(String cursor, {bool refresh = false}) =>
    ChangeFeed(nextCursor: cursor, refreshRequired: refresh);

void main() {
  late _Feed feed;
  late _Timers timers;
  late int refreshes;
  late bool refreshResult;
  late ChangePoller poller;

  setUp(() {
    feed = _Feed();
    timers = _Timers();
    refreshes = 0;
    refreshResult = true;
    poller = ChangePoller(
      repository: feed,
      onRefreshRequired: () async {
        refreshes++;
        return refreshResult;
      },
      interval: _interval,
      maxBackoff: const Duration(seconds: 40),
      requestTimeout: _timeout,
      timerFactory: timers.call,
    );
  });

  tearDown(() => poller.dispose());

  test('baseline is requested without cursor and never refreshes', () async {
    feed.responses.add(_feed('c1', refresh: true));
    expect(await poller.establishBaseline(), isTrue);
    expect(feed.afters, [null]);
    expect(refreshes, 0);
    expect(poller.hasBaseline, isTrue);
    // Ohne start() wird kein Poll geplant.
    expect(timers.polls, isEmpty);
  });

  test('refresh_required=false sends cursor and does not refresh', () async {
    feed.responses.addAll([
      _feed('c1'),
      ChangeFeed(
        nextCursor: 'c2',
        refreshRequired: false,
        // Hinweise allein lösen keinen Refresh aus.
        changes: const [
          {'entity': 'tasks', 'action': 'invalidate'},
        ],
      ),
      _feed('c3'),
    ]);
    await poller.establishBaseline();
    poller.start();
    expect(timers.polls.single.duration, _interval);
    timers.polls.single.fire();
    await pumpEventQueue();
    timers.polls.single.fire();
    await pumpEventQueue();
    expect(feed.afters, [null, 'c1', 'c2']);
    expect(refreshes, 0);
    expect(timers.polls, hasLength(1));
  });

  test(
    'refresh_required=true refreshes and then acknowledges cursor',
    () async {
      feed.responses.addAll([
        _feed('c1'),
        _feed('c2', refresh: true),
        _feed('c3'),
      ]);
      await poller.establishBaseline();
      await poller.pollNow();
      expect(refreshes, 1);
      await poller.pollNow();
      expect(feed.afters, [null, 'c1', 'c2']);
    },
  );

  test('failed refresh keeps old cursor, shows error and backs off', () async {
    feed.responses.addAll([
      _feed('c1'),
      _feed('c2', refresh: true),
      _feed('c2b'),
      _feed('c3'),
    ]);
    await poller.establishBaseline();
    poller.start();
    refreshResult = false;
    await poller.pollNow();
    expect(refreshes, 1);
    expect(poller.errorMessage, isNotNull);
    expect(poller.consecutiveFailures, 1);
    expect(timers.polls.single.duration, const Duration(seconds: 10));

    // Auch ohne erneutes refresh_required wird der Refresh wiederholt und der
    // alte Cursor erneut gesendet.
    refreshResult = true;
    await poller.pollNow();
    expect(feed.afters, [null, 'c1', 'c1']);
    expect(refreshes, 2);
    expect(poller.errorMessage, isNull);
    expect(timers.polls.single.duration, _interval);
    await poller.pollNow();
    expect(feed.afters.last, 'c2b');
  });

  test('backoff is bounded by maxBackoff', () async {
    feed.responses.addAll([
      for (var i = 0; i < 6; i++)
        const ApiException(statusCode: 503, message: 'down'),
    ]);
    poller.start();
    final delays = <Duration>[];
    for (var i = 0; i < 6; i++) {
      await poller.pollNow();
      delays.add(timers.polls.single.duration);
    }
    expect(delays.map((d) => d.inSeconds), [10, 20, 40, 40, 40, 40]);
    expect(poller.errorMessage, contains('down'));
    expect(poller.lastError, isA<ApiException>());
  });

  test('no overlapping requests and a single timer', () async {
    feed.responses.add(_feed('c1'));
    await poller.establishBaseline();
    poller.start();
    final hold = feed.hold = Completer<ChangeFeed>();
    final first = poller.pollNow();
    final second = poller.pollNow();
    poller.resume();
    expect(feed.afters, [null, 'c1']);
    expect(poller.isRequestInFlight, isTrue);
    expect(timers.polls, isEmpty);
    feed.hold = null;
    hold.complete(_feed('c2'));
    await Future.wait([first, second]);
    expect(poller.isRequestInFlight, isFalse);
    expect(timers.polls, hasLength(1));
  });

  test('pause stops scheduling; resume polls immediately', () async {
    feed.responses.addAll([_feed('c1'), _feed('c2')]);
    await poller.establishBaseline();
    poller.start();
    expect(timers.polls, hasLength(1));
    poller.pause();
    expect(timers.polls, isEmpty);
    expect(poller.isActive, isFalse);

    poller.resume();
    expect(feed.afters, [null, 'c1']);
    await pumpEventQueue();
    expect(timers.polls, hasLength(1));
  });

  test('pause during request does not reschedule afterwards', () async {
    feed.responses.add(_feed('c1'));
    await poller.establishBaseline();
    poller.start();
    final hold = feed.hold = Completer<ChangeFeed>();
    final pending = poller.pollNow();
    poller.pause();
    hold.complete(_feed('c2', refresh: true));
    await pending;
    expect(refreshes, 1);
    expect(timers.polls, isEmpty);
  });

  test('dispose and stop ignore late responses', () async {
    feed.responses.add(_feed('c1'));
    await poller.establishBaseline();
    poller.start();
    final hold = feed.hold = Completer<ChangeFeed>();
    unawaited(poller.pollNow());
    poller.stop();
    hold.complete(_feed('c2', refresh: true));
    await pumpEventQueue();
    expect(refreshes, 0);
    expect(timers.created.where((t) => t.isActive), isEmpty);
    poller.start();
    poller.resume();
    expect(timers.polls, isEmpty);
    expect(feed.afters, [null, 'c1']);
  });

  test('dispose cancels poll and timeout timers', () async {
    final local = ChangePoller(
      repository: feed..hold = Completer<ChangeFeed>(),
      onRefreshRequired: () async => true,
      requestTimeout: _timeout,
      timerFactory: timers.call,
    );
    local.start();
    unawaited(local.pollNow());
    expect(timers.timeouts, hasLength(1));
    local.dispose();
    expect(timers.created.where((t) => t.isActive), isEmpty);
  });

  test('401 stops polling with explicit state', () async {
    feed.responses.add(
      const ApiException(statusCode: 401, message: 'Nicht autorisiert.'),
    );
    poller.start();
    await poller.pollNow();
    expect(poller.isUnauthorized, isTrue);
    expect(poller.errorMessage, contains('Sitzung'));
    expect(timers.polls, isEmpty);
    poller.resume();
    expect(feed.afters, hasLength(1));
  });

  test('failed baseline forces new baseline plus refresh later', () async {
    feed.responses.addAll([
      const ApiException(statusCode: 500, message: 'down'),
      _feed('c1'),
      _feed('c2'),
    ]);
    expect(await poller.establishBaseline(), isFalse);
    expect(poller.hasBaseline, isFalse);
    expect(refreshes, 0);

    await poller.pollNow();
    expect(feed.afters, [null, null]);
    expect(refreshes, 1);
    expect(poller.hasBaseline, isTrue);
    await poller.pollNow();
    expect(feed.afters.last, 'c1');
    expect(refreshes, 1);
  });

  test('markRefreshRequired refreshes even without server change', () async {
    feed.responses.addAll([_feed('c1'), _feed('c2')]);
    await poller.establishBaseline();
    poller.markRefreshRequired();
    await poller.pollNow();
    expect(refreshes, 1);
  });

  test('hanging request times out and frees the in-flight slot', () async {
    feed.responses.add(_feed('c1'));
    await poller.establishBaseline();
    poller.start();
    feed.hold = Completer<ChangeFeed>();
    final pending = poller.pollNow();
    timers.timeouts.single.fire();
    await pending;
    expect(poller.isRequestInFlight, isFalse);
    expect(poller.lastError, isA<TimeoutException>());
    expect(timers.polls.single.duration, const Duration(seconds: 10));
  });
  test('invalid cursor (400) re-baselines before refresh', () async {
    feed.responses.addAll([
      _feed('c1'),
      const ApiException(statusCode: 400, message: 'Ungültiger Cursor'),
      _feed('fresh1'),
      _feed('fresh2'),
      _feed('c3'),
    ]);
    final order = <String>[];
    final local = ChangePoller(
      repository: feed,
      onRefreshRequired: () async {
        order.add('refresh after ${feed.afters.length} requests');
        refreshes++;
        return refreshResult;
      },
      requestTimeout: _timeout,
      timerFactory: timers.call,
    );
    addTearDown(local.dispose);
    await local.establishBaseline();

    // Erster Recovery-Versuch: Refresh scheitert, Cursor wird nicht übernommen.
    refreshResult = false;
    await local.pollNow();
    expect(feed.afters, [null, 'c1', null]);
    expect(order, ['refresh after 3 requests']);
    expect(local.hasBaseline, isFalse);
    expect(local.errorMessage, isNotNull);

    // Nächster Versuch holt wieder zuerst eine frische Baseline.
    refreshResult = true;
    await local.pollNow();
    expect(feed.afters, [null, 'c1', null, null]);
    expect(order.last, 'refresh after 4 requests');
    expect(local.errorMessage, isNull);
    await local.pollNow();
    expect(feed.afters.last, 'fresh2');
  });

  test('400 on a fresh baseline is reported, not looped', () async {
    feed.responses.addAll([
      const ApiException(statusCode: 400, message: 'kaputt'),
    ]);
    poller.start();
    await poller.pollNow();
    expect(feed.afters, [null]);
    expect(poller.errorMessage, contains('kaputt'));
    expect(timers.polls, hasLength(1));
  });
}
