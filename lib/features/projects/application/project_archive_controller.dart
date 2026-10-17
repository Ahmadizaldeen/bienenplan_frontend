import 'package:flutter/foundation.dart';

import '../../subtasks/data/subtask_model.dart';
import '../../subtasks/data/subtask_repository.dart';
import '../../tasks/data/task_attachment.dart';
import '../../tasks/data/task_attachment_repository.dart';
import '../data/project_archive_repository.dart';
import '../data/project_model.dart';

class ProjectArchiveController extends ChangeNotifier {
  ProjectArchiveController({
    ProjectArchiveRepositoryContract? repository,
    SubtaskRepositoryContract? subtaskRepository,
    TaskAttachmentRepositoryContract? attachmentRepository,
    this._refreshActiveProjects,
  }) : _repository = repository ?? ProjectArchiveRepository(),
       _subtaskRepository = subtaskRepository ?? SubtaskRepository(),
       _attachmentRepository =
           attachmentRepository ?? TaskAttachmentRepository();

  final ProjectArchiveRepositoryContract _repository;
  final SubtaskRepositoryContract _subtaskRepository;
  final TaskAttachmentRepositoryContract _attachmentRepository;
  final Future<String?> Function()? _refreshActiveProjects;
  List<Project> projects = const [];
  bool isLoading = false;
  int? restoringId;
  String? errorMessage;
  String? refreshErrorMessage;
  bool _disposed = false;

  void _notify() {
    // Ein Request kann erst nach dem Verlassen des Archivscreens abschliessen.
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    refreshErrorMessage = null;
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
      final refreshActiveProjects = _refreshActiveProjects;
      if (refreshActiveProjects != null) {
        refreshErrorMessage = await refreshActiveProjects();
      }
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      restoringId = null;
      _notify();
    }
  }

  Future<ArchivedProjectContents> fetchContents(int projectId) =>
      _repository.fetchContents(projectId);

  Future<(SubtaskList, List<TaskAttachment>)> fetchTaskDetails(
    int taskId,
  ) async {
    final subtasks = await _subtaskRepository.list(taskId);
    final attachments = await _attachmentRepository.list(taskId);
    return (subtasks, attachments);
  }

  Future<Uint8List> downloadAttachment(int taskId, int attachmentId) =>
      _attachmentRepository.download(taskId, attachmentId);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
