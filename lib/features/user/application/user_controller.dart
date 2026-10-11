import 'package:flutter/foundation.dart';

import '../data/user_model.dart';
import '../data/user_repository.dart';

class UserController extends ChangeNotifier {
  UserController({UserRepositoryContract? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  final UserRepositoryContract _userRepository;

  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _currentUser;
  Uint8List? _currentProfilePictureBytes;
  bool _disposed = false;
  int _loadVersion = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  Uint8List? get currentProfilePictureBytes => _currentProfilePictureBytes;

  /// Lädt den aktuellen Benutzer. Liefert `true`, wenn genau dieser Load
  /// übernommen wurde. Mit [silent] bleiben Ladezustand, bisheriger Benutzer
  /// und Fehlermeldung bei einem Fehler unverändert.
  Future<bool> loadCurrentUser({bool silent = false}) async {
    if (_disposed) return false;
    final version = ++_loadVersion;
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final user = await _userRepository.fetchCurrentUser();
      if (_disposed || version != _loadVersion) return false;
      // Nach einem Neustart ist die Backend-URL die persistente Bildquelle;
      // lokale Upload-Bytes gelten nur für die unmittelbare Vorschau. Ein
      // stiller Refresh behält sie nur, solange sich das Bild nicht geändert hat.
      if (!silent || user.picture != _currentUser?.picture) {
        _currentProfilePictureBytes = null;
      }
      _currentUser = user;
      _errorMessage = null;
      return true;
    } catch (error) {
      if (_disposed || version != _loadVersion || silent) return false;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _currentUser = null;
      return false;
    } finally {
      if (version == _loadVersion) {
        _isLoading = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<bool> uploadProfilePicture(Uint8List bytes, String filename) async {
    // Ein gemeinsamer Ladezustand verhindert parallele Profilaktionen und
    // ermöglicht der Präsentationsschicht, ihre Bedienelemente zu sperren.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Der zurückgegebene Benutzer ersetzt den lokalen Zustand atomar.
      _currentUser = await _userRepository.uploadProfilePicture(
        bytes,
        filename,
      );
      // Zeigt das gerade hochgeladene Bild sofort an, ohne auf den
      // Browser- oder HTTP-Bildcache angewiesen zu sein.
      _currentProfilePictureBytes = Uint8List.fromList(bytes);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
