class Task {
  final int id;
  final int containerId;
  final int? projectId;
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
  final List<int> groupIds;
  final List<String> groupNames;

  Task({
    required this.id,
    required this.containerId,
    this.projectId,
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
    this.groupIds = const [],
    this.groupNames = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Backend liefert bei manchen Endpunkten "group_ids"/"group_names" als
    // kommaseparierten String (SQL GROUP_CONCAT).
    List<int> parseGroupIds(dynamic value) {
      if (value == null) return const [];
      final raw = value.toString();
      if (raw.isEmpty) return const [];
      return raw
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    }

    List<String> parseGroupNames(dynamic value) {
      if (value == null) return const [];
      final raw = value.toString();
      if (raw.isEmpty) return const [];
      return raw.split(',').map((e) => e.trim()).toList();
    }

    return Task(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      containerId: json['container_id'] is int
          ? json['container_id']
          : int.tryParse(json['container_id'].toString()) ?? 0,
      projectId: json['project_id'] != null
          ? (json['project_id'] is int
                ? json['project_id']
                : int.tryParse(json['project_id'].toString()))
          : null,
      createdBy: json['created_by'] is int
          ? json['created_by']
          : int.tryParse(json['created_by'].toString()) ?? 0,
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
      groupIds: parseGroupIds(json['group_ids']),
      groupNames: parseGroupNames(json['group_names']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'container_id': containerId,
      'project_id': projectId,
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

  /// Dateiname des Anhangs für die Anzeige (ohne Pfad).
  String? get attachmentFileName {
    if (attachment == null || attachment!.isEmpty) return null;
    return attachment!.split('/').last;
  }
}
