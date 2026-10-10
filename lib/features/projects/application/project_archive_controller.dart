import 'package:flutter/foundation.dart';

import '../data/project_archive_repository.dart';
import '../data/project_model.dart';

class ProjectArchiveController extends ChangeNotifier {
  ProjectArchiveController({ProjectArchiveRepository? repository})
    : _repository = repository ?? ProjectArchiveRepository();

  final ProjectArchiveRepository _repository;
  List<Project> projects = const [];
  bool isLoading = false;
  int? restoringId;
  String? errorMessage;
  bool _disposed = false;

  void _notify() {
    // Ein Request kann erst nach dem Verlassen des Archivscreens abschliessen.
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      final result = await _repository.fetchArchivedProjects();
      if (!_disposed) projects = result;
    } catch (error) {
      if (!_disposed) errorMessage = error.toString();
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<bool> restore(Project project) async {
    if (restoringId != null) return false;
    restoringId = project.id;
    errorMessage = null;
    _notify();
    try {
      await _repository.restore(project.id);
      projects = projects.where((item) => item.id != project.id).toList();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      restoringId = null;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
