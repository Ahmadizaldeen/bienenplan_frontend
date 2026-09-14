class Project {
  final int id;
  final String name;
  final bool isActive;

  const Project({required this.id, required this.name, this.isActive = false});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['isActive'] == true ||
          json['isActive'] == 1 ||
          json['isActive'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'is_active': isActive};
  }
}
