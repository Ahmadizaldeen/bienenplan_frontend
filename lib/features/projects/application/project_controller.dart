import 'package:flutter/foundation.dart';

import '../data/project_model.dart';
import '../data/project_repository.dart';
import '../data/project_local_store.dart';

class ProjectController extends ChangeNotifier {
  ProjectController({ProjectRepositoryContract? projectRepository, ProjectLocalStore? projectLocalStore})
    : _projectRepository = projectRepository ?? ProjectRepository(),
      _projectLocalStore = projectLocalStore ?? ProjectLocalStore();

  final ProjectRepositoryContract _projectRepository;
  final ProjectLocalStore _projectLocalStore;

  bool _isLoading = false;
  String? _errorMessage;
  List<Project> _projects = const [];
  int? _selectedProjectId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Project> get projects => _projects;
  Project? get selectedProject {
    if (_selectedProjectId == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == _selectedProjectId);
    } catch (_) {
      return null;
    }
  }

    void selectProject(int projectId) {
    _selectedProjectId = projectId;
    _projectLocalStore.setSelectedProjectId(projectId); // fire-and-forget, kein await nötig
    notifyListeners();
  }

  Future<void> loadProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _projects = await _projectRepository.fetchProjects();

      // Beim ersten Laden gespeicherte Auswahl wiederherstellen.
      _selectedProjectId ??= await _projectLocalStore.getSelectedProjectId();

      // Falls das gespeicherte Projekt nicht mehr existiert (z.B. gelöscht),
      // auf das erste verfügbare Projekt zurückfallen.
      final stillExists =
          _projects.any((p) => p.id == _selectedProjectId);
      if (!stillExists) {
        _selectedProjectId = _projects.isNotEmpty ? _projects.first.id : null;
      }
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
