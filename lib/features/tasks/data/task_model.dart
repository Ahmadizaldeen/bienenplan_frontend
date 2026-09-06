class Task {
  final int id;
  final int containerId;
  final int createdBy;
  final String title;
  final String description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? deadline;
  final String? attachment;
  final String? deletedAt;
  final int? deletedBy;
  final String containerTitle;
  final String creatorName;

  Task({
    required this.id,
    required this.containerId,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deadline,
    this.attachment,
    this.deletedAt,
    this.deletedBy,
    required this.containerTitle,
    required this.creatorName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      containerId: json['container_id'] is int
          ? json['container_id']
          : int.parse(json['container_id'].toString()),
      createdBy: json['created_by'] is int
          ? json['created_by']
          : int.parse(json['created_by'].toString()),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deadline: json['deadline'],
      attachment: json['attachment'],
      deletedAt: json['deleted_at'],
      deletedBy: json['deleted_by'] != null
          ? (json['deleted_by'] is int
              ? json['deleted_by']
              : int.tryParse(json['deleted_by'].toString()))
          : null,
      containerTitle: json['container_title'] ?? '',
      creatorName: json['creator_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'container_id': containerId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deadline': deadline,
      'attachment': attachment,
      'deleted_at': deletedAt,
      'deleted_by': deletedBy,
      'container_title': containerTitle,
      'creator_name': creatorName,
    };
  }

  // Parse String to DateTime for Null-Safety
  DateTime? get deadlineDateTime {
    if (deadline == null || deadline!.isEmpty) return null;
    return DateTime.tryParse(deadline!);
  }

  // Safe formatted deadline String (prevents null reference bugs)
  String get formattedDeadline {
  final date = deadlineDateTime;
  if (date == null) return 'Keine Frist';
  
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute';
}
}
