import 'package:flutter/foundation.dart';

import '../data/project_model.dart';
import '../data/project_group_model.dart';
import '../data/project_repository.dart';
import '../data/project_local_store.dart';
import '../../user/data/user_model.dart';

enum ProjectMutationResult { failed, succeeded, refreshFailed }

class ProjectController extends ChangeNotifier {
  ProjectController({
    ProjectRepositoryContract? projectRepository,
    ProjectLocalStoreContract? projectLocalStore,
  }) : _projectRepository = projectRepository ?? ProjectRepository(),
       _projectLocalStore = projectLocalStore ?? ProjectLocalStore();

  final ProjectRepositoryContract _projectRepository;
  final ProjectLocalStoreContract _projectLocalStore;

  bool _isLoading = false;
  String? _errorMessage;
  List<Project> _projects = const [];
  int? _selectedProjectId;
  bool _disposed = false;
  int _groupsRevision = 0;
  int _loadVersion = 0;

  bool get isLoading => _isLoading;
  int get groupsRevision => _groupsRevision;
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
    if (_disposed) return;
    _selectedProjectId = projectId;
    _projectLocalStore.setSelectedProjectId(projectId);
    _notify();
  }

  Future<void> loadProjects() async {
    if (_disposed) return;
    final version = ++_loadVersion;
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final projects = await _projectRepository.fetchProjects();
      if (_disposed || version != _loadVersion) return;

      // Beim ersten Laden gespeicherte Auswahl wiederherstellen.
      if (_selectedProjectId == null) {
        final storedId = await _projectLocalStore.getSelectedProjectId();
        if (_disposed || version != _loadVersion) return;
        _selectedProjectId ??= storedId;
      }
      _projects = projects;

      // Falls das gespeicherte Projekt nicht mehr existiert (z.B. gelöscht),
      // auf das erste verfügbare Projekt zurückfallen.
      final stillExists = _projects.any((p) => p.id == _selectedProjectId);
      if (!stillExists) {
        _selectedProjectId = _projects.isNotEmpty ? _projects.first.id : null;
      }
    } catch (error) {
      if (_disposed || version != _loadVersion) return;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      if (version == _loadVersion) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<ProjectMutationResult> createProject(String name) async {
    if (_disposed) return ProjectMutationResult.failed;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Projektname darf nicht leer sein.';
      _notify();
      return ProjectMutationResult.failed;
    }

    return _mutateProject(() => _projectRepository.createProject(trimmed));
  }

  Future<ProjectMutationResult> updateProject(int id, String name) async {
    if (_disposed) return ProjectMutationResult.failed;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Projektname darf nicht leer sein.';
      _notify();
      return ProjectMutationResult.failed;
    }

    return _mutateProject(() => _projectRepository.updateProject(id, trimmed));
  }

  Future<ProjectMutationResult> archiveProject(int id) =>
      _mutateProject(() => _projectRepository.archiveProject(id));

  Future<ProjectMutationResult> _mutateProject(
    Future<void> Function() action,
  ) async {
    if (_disposed) return ProjectMutationResult.failed;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      await action();
      if (_disposed) return ProjectMutationResult.succeeded;
      await loadProjects();
      // Ein erfolgreicher Schreibvorgang darf bei Refresh-Fehlern nicht erneut
      // gesendet werden; die UI bietet stattdessen nur das Neuladen an.
      return _errorMessage == null
          ? ProjectMutationResult.succeeded
          : ProjectMutationResult.refreshFailed;
    } catch (error) {
      if (!_disposed) {
        _errorMessage = error.toString().replaceAll('Exception: ', '');
      }
      return ProjectMutationResult.failed;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // Leseanfragen des Gruppendialogs haben eigene Fehlerzustände. Ein gemeinsames
  // errorMessage würde bei den parallelen Requests Erfolg und Fehler vermischen.
  Future<List<ProjectGroup>> fetchProjectGroups(int projectId) =>
      _projectRepository.fetchProjectGroups(projectId);

  Future<List<ProjectGroup>> fetchAvailableGroups(int projectId) async {
    final groups = await _projectRepository.fetchAvailableGroups();
    return groups.where((group) => group.isAvailableFor(projectId)).toList();
  }

  Future<bool> setProjectGroup(
    int projectId,
    int groupId,
    bool assigned,
  ) async {
    if (_disposed) return false;
    _errorMessage = null;
    try {
      if (assigned) {
        await _projectRepository.assignGroup(projectId, groupId);
      } else {
        // Das Backend entfernt dabei auch die Aufgabenzuweisungen dieser Gruppe
        // innerhalb des Projekts, nicht nur ihren Eintrag in der Projektliste.
        await _projectRepository.removeGroup(projectId, groupId);
      }
      if (_disposed) return true;
      _errorMessage = null;
      _groupsRevision++;
      _notify();
      return true;
    } catch (error) {
      if (_disposed) return false;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _notify();
      return false;
    }
  }

  Future<List<GroupUser>> fetchUsers() => _projectRepository.fetchUsers();

  Future<bool> createProjectGroup(
    int projectId,
    String name,
    List<int> userIds,
  ) async {
    if (_disposed) return false;
    _errorMessage = null;
    try {
      await _projectRepository.createGroup(projectId, name, userIds);
      if (_disposed) return true;
      _errorMessage = null;
      _groupsRevision++;
      _notify();
      return true;
    } catch (error) {
      if (_disposed) return false;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
