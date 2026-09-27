import 'package:flutter/foundation.dart';

import '../data/container_model.dart' as container_model;
import '../data/task_model.dart';
import '../data/container_repository.dart';
import '../data/task_repository.dart';
import '../data/group_model.dart';
import '../data/group_repository.dart';
import '../../user/data/user_model.dart';

class TaskController extends ChangeNotifier {
  TaskController({
    TaskRepositoryContract? taskRepository,
    ContainerRepositoryContract? containerRepository,
    GroupRepositoryContract? groupRepository,
  }) : _taskRepository = taskRepository ?? TaskRepository(),
       _containerRepository = containerRepository ?? ContainerRepository(),
       _groupRepository = groupRepository ?? GroupRepository();

  final TaskRepositoryContract _taskRepository;
  final ContainerRepositoryContract _containerRepository;
  final GroupRepositoryContract _groupRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Task> _tasks = const [];
  List<container_model.Container> _extraContainers = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;
  List<container_model.Container> get extraContainers =>
      List.unmodifiable(_extraContainers);

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _taskRepository.fetchTasks(),
        _containerRepository.fetchContainers(),
      ]);
      _tasks = results[0] as List<Task>;
      _extraContainers = results[1] as List<container_model.Container>;
    } catch (error) {
      _errorMessage = _messageOf(error);
      _tasks = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<List<Group>> fetchAllGroups() {
    return _guard(_groupRepository.fetchAllGroups, const <Group>[]);
  }

  Future<List<Group>> fetchGroupsForTask(int taskId) {
    return _guard(
      () => _groupRepository.fetchGroupsForTask(taskId),
      const <Group>[],
    );
  }

  Future<List<GroupUser>?> fetchAllUsers() {
    return _guard<List<GroupUser>?>(_groupRepository.fetchAllUsers, null);
  }

  Future<Group?> createGroup(
    String name, {
    List<int> userIds = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Der Gruppenname darf nicht leer sein.';
      notifyListeners();
      return null;
    }

    return _guard<Group?>(() async {
      final group = await _groupRepository.createGroup(
        trimmedName,
        userIds: userIds,
      );
      _errorMessage = null;
      return group;
    }, null);
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
}
