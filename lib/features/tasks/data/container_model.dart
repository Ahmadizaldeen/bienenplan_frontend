class Container {
  final int id;
  final String title;
  final int? projectId;
  final bool canManage;

  const Container({
    required this.id,
    required this.title,
    this.projectId,
    this.canManage = false,
  });

  Container copyWith({
    int? id,
    String? title,
    int? projectId,
    bool? canManage,
  }) {
    return Container(
      id: id ?? this.id,
      title: title ?? this.title,
      projectId: projectId ?? this.projectId,
      canManage: canManage ?? this.canManage,
    );
  }

  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      projectId: json['project_id'] != null
          ? (json['project_id'] is int
                ? json['project_id'] as int
                : int.tryParse(json['project_id'].toString()))
          : null,
      canManage:
          json['can_manage'] == true ||
          json['can_manage'] == 1 ||
          json['can_manage'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (projectId != null) 'project_id': projectId,
      'can_manage': canManage,
    };
  }
}
