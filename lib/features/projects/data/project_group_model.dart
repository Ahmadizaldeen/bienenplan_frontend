class ProjectGroup {
  final int id;
  final String name;
  final int? projectId;
  final bool isGlobal;
  final int? personalUserId;
  final int? memberCount;

  const ProjectGroup({
    required this.id,
    required this.name,
    this.projectId,
    this.isGlobal = false,
    this.personalUserId,
    this.memberCount,
  });

  // Fehlender Projektscope bedeutet nicht global: Altgruppen bleiben ausgeschlossen.
  bool isAvailableFor(int id) =>
      personalUserId == null &&
      ((isGlobal && projectId == null) || (!isGlobal && projectId == id));

  factory ProjectGroup.fromJson(Map<String, dynamic> json) {
    return ProjectGroup(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: (json['personal_user_name'] ?? json['name'] ?? '').toString(),
      projectId: int.tryParse('${json['project_id']}'),
      isGlobal:
          json['is_global'] == true ||
          json['is_global'] == 1 ||
          json['is_global'] == '1',
      personalUserId: int.tryParse('${json['personal_user_id']}'),
      memberCount: int.tryParse('${json['member_count']}'),
    );
  }
}
