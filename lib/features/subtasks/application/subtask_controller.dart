import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/subtask_model.dart';
import '../data/subtask_repository.dart';

class SubtaskController extends ChangeNotifier {
  SubtaskController({required this.taskId, required this._repository});

  final int taskId;
  final SubtaskRepositoryContract _repository;
  List<Subtask> _items = const [];
  bool _canCreate = false;
  bool _loaded = false;
  bool _loading = false;
  bool _mutating = false;
  bool _disposed = false;
  String? _error;

  List<Subtask> get items => List.unmodifiable(_items);
  bool get canCreate => _canCreate;
  bool get loaded => _loaded;
  bool get loading => _loading;
  bool get mutating => _mutating;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_disposed || _loading || _mutating || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.list(taskId);
      if (_disposed) return;
      _items = [...result.items]
        ..sort((first, second) => first.id.compareTo(second.id));
      _canCreate = result.canCreate;
      _loaded = true;
    } catch (error) {
      if (!_disposed) _error = _message(error);
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Teilaufgaben konnten nicht gespeichert oder geladen werden.';

  Future<bool> _mutate(Future<void> Function() action) async {
    if (_disposed || !_loaded || _loading || _mutating) return false;
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return !_disposed;
    } catch (error) {
      if (!_disposed) _error = _message(error);
      return false;
    } finally {
      if (!_disposed) {
        _mutating = false;
        notifyListeners();
      }
    }
  }

  Future<bool> create(String title) {
    if (!_canCreate) return Future.value(false);
    return _mutate(() async {
      final item = await _repository.create(taskId, title);
      if (_disposed) return;
      _items = [..._items, item]
        ..sort((first, second) => first.id.compareTo(second.id));
    });
  }

  Future<bool> update(Subtask item, {String? title, bool? completed}) {
    if ((title != null && !item.canEdit) ||
        (completed != null && !item.canComplete)) {
      return Future.value(false);
    }
    return _mutate(() async {
      final updated = await _repository.update(
        taskId,
        item.id,
        title: title,
        completed: completed,
      );
      if (_disposed) return;
      // Apply server-confirmed data only; failed requests leave the checklist intact.
      _items = _items
          .map((existing) => existing.id == item.id ? updated : existing)
          .toList();
    });
  }

  Future<bool> delete(Subtask item) {
    if (!item.canDelete) return Future.value(false);
    return _mutate(() async {
      await _repository.delete(taskId, item.id);
      if (!_disposed) {
        _items = _items.where((existing) => existing.id != item.id).toList();
      }
    });
  }

  @override
  void dispose() {
    // Closing the task dialog must not notify a disposed Provider after an API call.
    _disposed = true;
    super.dispose();
  }
}
