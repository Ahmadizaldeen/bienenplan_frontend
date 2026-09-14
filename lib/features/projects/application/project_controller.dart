import 'package:flutter/foundation.dart';

import '../data/project_model.dart';
import '../data/project_repository.dart';

class ProjectController extends ChangeNotifier {
  ProjectController({ProjectRepositoryContract? projectRepository})
    : _projectRepository = projectRepository ?? ProjectRepository();

  final ProjectRepositoryContract _projectRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Project> _projects = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Project> get projects => _projects;

  Future<void> loadProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await _projectRepository.fetchProjects();
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _projects = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Projektname darf nicht leer sein.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _projectRepository.createProject(trimmed);
      await loadProjects();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
