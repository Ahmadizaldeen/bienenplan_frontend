class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.originalName,
    required this.sizeBytes,
    required this.canDelete,
  });

  final int id;
  final String originalName;
  final int sizeBytes;
  final bool canDelete;

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
    id: (json['id'] as num).toInt(),
    originalName: json['original_name'] as String,
    sizeBytes: (json['size_bytes'] as num).toInt(),
    canDelete: json['can_delete'] == true || json['can_delete'] == 1,
  );
}
