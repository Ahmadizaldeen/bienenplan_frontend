import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepositoryContract? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepositoryContract _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.login(email, password);

      if (!success) {
        _errorMessage = 'Anmeldung fehlgeschlagen. Ungültige Zugangsdaten.';
      }

      return success;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      final errorStr = error.toString();
      _errorMessage = 'Fehler: ${errorStr.replaceAll('Exception: ', '')}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    notifyListeners();
  }
}
