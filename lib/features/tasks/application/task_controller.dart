import 'package:flutter/foundation.dart';

import '../data/container_model.dart' as container_model;
import '../data/task_model.dart';
import '../data/container_repository.dart';
import '../data/task_repository.dart';
import '../data/group_model.dart';
import '../data/group_repository.dart';

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
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      _tasks = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    try {
      await _taskRepository.updateTaskStatus(taskId, newStatus);
      await loadTasks();
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Lädt eine einzelne Aufgabe mit allen Details (u.a. Gruppen) neu, z.B.
  /// für die Detailansicht. Aktualisiert nicht die Task-Liste selbst.
  Future<Task?> fetchTaskDetail(int taskId) async {
    try {
      return await _taskRepository.fetchTaskDetail(taskId);
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTask(
    int taskId, {
    required String title,
    String description = '',
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      _errorMessage = 'Aufgaben-Titel darf nicht leer sein.';
      notifyListeners();
      return false;
    }

    try {
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
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadTaskAttachment(
    int taskId,
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final attachment = await _taskRepository.uploadAttachment(
        taskId,
        bytes,
        filename,
      );
      await loadTasks();
      return attachment;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<List<Group>> fetchAllGroups() async {
    try {
      return await _groupRepository.fetchAllGroups();
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return const [];
    }
  }

  Future<List<Group>> fetchGroupsForTask(int taskId) async {
    try {
      return await _groupRepository.fetchGroupsForTask(taskId);
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return const [];
    }
  }

  Future<bool> assignGroupToTask(int taskId, int groupId) async {
    try {
      await _groupRepository.assignGroupToTask(taskId, groupId);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeGroupFromTask(int taskId, int groupId) async {
    try {
      await _groupRepository.removeGroupFromTask(taskId, groupId);
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTask({
    required int containerId,
    required String title,
    String description = '',
    String status = 'pending',
    String? deadline,
    String? attachment,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      _errorMessage = 'Aufgaben-Titel darf nicht leer sein.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskRepository.createTask(
        containerId: containerId,
        title: trimmedTitle,
        description: description.trim(),
        status: status,
        deadline: deadline,
        attachment: attachment,
      );
      await loadTasks();
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      return false;
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
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
