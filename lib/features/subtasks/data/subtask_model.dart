class Subtask {
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.completed,
    required this.canEdit,
    required this.canDelete,
    required this.canComplete,
    this.createdBy,
  });

  final int id;
  final int taskId;
  final String title;
  final bool completed;
  final int? createdBy;
  final bool canEdit;
  final bool canDelete;
  final bool canComplete;

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as int,
    taskId: json['task_id'] as int,
    title: json['title'] as String,
    completed: json['completed'] as bool,
    createdBy: json['created_by'] as int?,
    canEdit: json['can_edit'] as bool,
    canDelete: json['can_delete'] as bool,
    canComplete: json['can_complete'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_id': taskId,
    'title': title,
    'completed': completed,
    'created_by': createdBy,
    'can_edit': canEdit,
    'can_delete': canDelete,
    'can_complete': canComplete,
  };
}

class SubtaskList {
  SubtaskList({required List<Subtask> items, required this.canCreate})
    : items = List.unmodifiable(items);

  final List<Subtask> items;
  final bool canCreate;
}
