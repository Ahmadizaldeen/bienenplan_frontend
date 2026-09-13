class Project {
  final int id;
  final String name;
  final bool isActive;

  const Project({required this.id, required this.name, this.isActive = false});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      isActive: json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'is_active': isActive};
  }
}
