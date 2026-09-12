import 'package:flutter/foundation.dart';

import '../data/task_model.dart';
import '../data/task_repository.dart';

class TaskController extends ChangeNotifier {
  TaskController({TaskRepositoryContract? taskRepository})
      : _taskRepository = taskRepository ?? TaskRepository();

  final TaskRepositoryContract _taskRepository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Task> _tasks = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.fetchTasks();
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
}
