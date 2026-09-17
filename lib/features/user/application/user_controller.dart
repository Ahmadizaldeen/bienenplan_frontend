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

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _userRepository.fetchCurrentUser();
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
