class Project {
  final int id;
  final String name;
  final bool isOwner;
  // Aktionsrechte kommen vom Backend; isOwner allein bildet Adminrechte nicht ab.
  final bool canEdit;
  final bool canDelete;
  final bool canManageGroups;
  final bool canRestore;
  final String? archivedAt;

  const Project({
    required this.id,
    required this.name,
    this.isOwner = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canManageGroups = false,
    this.canRestore = false,
    this.archivedAt,
  });

  static bool _flag(dynamic value) =>
      value == true || value == 1 || value == '1';

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      isOwner:
          json['is_owner'] == true ||
          json['is_owner'] == 1 ||
          json['is_owner'] == '1',
      canEdit: _flag(json['can_edit']),
      canDelete: _flag(json['can_delete']),
      canManageGroups: _flag(json['can_manage_groups']),
      canRestore: _flag(json['can_restore']),
      archivedAt: json['archived_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
