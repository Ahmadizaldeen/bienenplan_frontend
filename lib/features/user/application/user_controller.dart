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

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  Uint8List? get currentProfilePictureBytes => _currentProfilePictureBytes;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _userRepository.fetchCurrentUser();
      // Nach einem Neustart ist die Backend-URL die persistente Bildquelle;
      // lokale Upload-Bytes gelten nur für die unmittelbare Vorschau.
      _currentProfilePictureBytes = null;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      notifyListeners();
    }
  }
}
