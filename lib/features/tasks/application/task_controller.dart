import 'package:flutter/foundation.dart';

import '../data/container_model.dart' as container_model;
import '../data/task_model.dart';
import '../data/container_repository.dart';
import '../data/task_repository.dart';
import '../data/task_attachment.dart';
import '../data/task_attachment_repository.dart';
import '../data/group_model.dart';
import '../data/group_repository.dart';

class TaskController extends ChangeNotifier {
  TaskController({
    TaskRepositoryContract? taskRepository,
    ContainerRepositoryContract? containerRepository,
    GroupRepositoryContract? groupRepository,
    TaskAttachmentRepository? attachmentRepository,
  }) : _taskRepository = taskRepository ?? TaskRepository(),
       _containerRepository = containerRepository ?? ContainerRepository(),
       _groupRepository = groupRepository ?? GroupRepository(),
       _attachmentRepository =
           attachmentRepository ?? TaskAttachmentRepository();

  final TaskRepositoryContract _taskRepository;
  final ContainerRepositoryContract _containerRepository;
  final GroupRepositoryContract _groupRepository;
  final TaskAttachmentRepository _attachmentRepository;

  Future<List<TaskAttachment>> listAttachments(int taskId) =>
      _attachmentRepository.list(taskId);

  Future<List<TaskAttachment>> uploadAttachments(
    int taskId,
    List<({String name, Uint8List bytes})> files,
  ) => _attachmentRepository.upload(taskId, files);

  Future<Uint8List> downloadAttachment(int taskId, int attachmentId) =>
      _attachmentRepository.download(taskId, attachmentId);

  Future<void> deleteAttachment(int taskId, int attachmentId) =>
      _attachmentRepository.delete(taskId, attachmentId);

  bool _isLoading = false;
  String? _errorMessage;
  List<Task> _tasks = const [];
  List<container_model.Container> _extraContainers = const [];
  bool _disposed = false;
  int _loadVersion = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;
  List<container_model.Container> get extraContainers =>
      List.unmodifiable(_extraContainers);

  Future<void> loadTasks() async {
    if (_disposed) return;
    final version = ++_loadVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _taskRepository.fetchTasks(),
        _containerRepository.fetchContainers(),
      ]);
      if (_disposed || version != _loadVersion) return;
      _tasks = results[0] as List<Task>;
      _extraContainers = results[1] as List<container_model.Container>;
    } catch (error) {
      if (_disposed || version != _loadVersion) return;
      _errorMessage = _messageOf(error);
      _tasks = const [];
      _extraContainers = const [];
    } finally {
      if (version == _loadVersion) {
        _isLoading = false;
        if (!_disposed) notifyListeners();
      }
    }
  }

  // Einheitliche Fehlermeldung ohne "Exception: "-Präfix.
  String _messageOf(Object error) =>
      error.toString().replaceAll('Exception: ', '');

  // Gemeinsame Fehlerbehandlung (ersetzt den vorher in jeder Methode
  // wiederholten try/catch): Fehler merken, UI benachrichtigen, Fallback liefern.
  Future<T> _guard<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (error) {
      _errorMessage = _messageOf(error);
      notifyListeners();
      return fallback;
    }
  }

  Future<void> updateTaskStatus(int taskId, String newStatus) {
    return _guard(() async {
      await _taskRepository.updateTaskStatus(taskId, newStatus);
      await loadTasks();
    }, null);
  }

  /// Lädt eine einzelne Aufgabe mit allen Details (u.a. Gruppen) neu, z.B.
  /// für die Detailansicht. Aktualisiert nicht die Task-Liste selbst.
  Future<Task?> fetchTaskDetail(int taskId) {
    return _guard<Task?>(() => _taskRepository.fetchTaskDetail(taskId), null);
  }

  Future<bool> deleteTask(int taskId) async {
    _errorMessage = null;
    // API-Fehler bewusst weitergeben: Der Dialog zeigt die Ablehnung samt
    // Backend-Meldung, statt sie auf einen booleschen Fallback zu reduzieren.
    await _taskRepository.deleteTask(taskId);
    await loadTasks();
    return true;
  }

  Future<bool> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      _errorMessage = 'Aufgaben-Titel darf nicht leer sein.';
      notifyListeners();
      return false;
    }

    return _guard(() async {
      await _taskRepository.updateTask(
        taskId,
        title: trimmedTitle,
        description: description.trim(),
        status: status,
        deadline: deadline,
        attachment: attachment,
      );
      await loadTasks();
      return true;
    }, false);
  }

  Future<String?> uploadTaskAttachment(
    int taskId,
    Uint8List bytes,
    String filename,
  ) {
    return _guard<String?>(() async {
      final attachment = await _taskRepository.uploadAttachment(
        taskId,
        bytes,
        filename,
      );
      await loadTasks();
      return attachment;
    }, null);
  }

  Future<List<Group>> fetchGroupsForProject(int projectId) {
    return _guard(
      () => _groupRepository.fetchGroupsForProject(projectId),
      const <Group>[],
    );
  }

  Future<List<Group>> fetchGroupsForTask(int taskId) {
    return _guard(
      () => _groupRepository.fetchGroupsForTask(taskId),
      const <Group>[],
    );
  }

  Future<bool> assignGroupToTask(int taskId, int groupId) {
    return _guard(() async {
      await _groupRepository.assignGroupToTask(taskId, groupId);
      return true;
    }, false);
  }

  Future<bool> removeGroupFromTask(int taskId, int groupId) {
    return _guard(() async {
      await _groupRepository.removeGroupFromTask(taskId, groupId);
      return true;
    }, false);
  }

  Future<bool> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
    Set<int> groupIds = const {},
  }) async {
    return await createTaskWithId(
          containerId: containerId,
          title: title,
          description: description,
          status: status,
          deadline: deadline,
          attachment: attachment,
          groupIds: groupIds,
        ) !=
        null;
  }

  Future<int?> createTaskWithId({
    required int containerId,
    required String title,
    String description = '',
    String status = 'open',
    String? deadline,
    String? attachment,
    Set<int> groupIds = const {},
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      _errorMessage = 'Aufgaben-Titel darf nicht leer sein.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final taskId = await _taskRepository.createTask(
        containerId: containerId,
        title: trimmedTitle,
        description: description.trim(),
        status: status,
        deadline: deadline,
        attachment: attachment,
      );
      for (final groupId in groupIds) {
        await assignGroupToTask(taskId, groupId);
        if (_errorMessage != null) return null;
      }
      await loadTasks();
      return taskId;
    } catch (error) {
      _errorMessage = _messageOf(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createContainer(String title, {int? projectId}) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      _errorMessage = 'Container-Titel darf nicht leer sein.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _containerRepository.createContainer(
        trimmedTitle,
        projectId: projectId,
      );
      await loadTasks();
      return true;
    } catch (error) {
      _errorMessage = _messageOf(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
