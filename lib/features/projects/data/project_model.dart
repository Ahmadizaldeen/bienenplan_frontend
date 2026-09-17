class Project {
  final int id;
  final String name;
  
  const Project({required this.id, required this.name});



  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: (json['name'] ?? json['title'] ?? '').toString(),
    
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
