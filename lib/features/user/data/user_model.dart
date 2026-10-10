class AppUser {
  final int id;
  final String name;
  final String email;
  final String? picture;
  final bool isAdmin;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.picture,
    this.isAdmin = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] as String,
      email: json['email'] as String,
      picture: json['picture'] as String?,
      isAdmin:
          json['is_admin'] == true ||
          json['is_admin'] == 1 ||
          json['is_admin'] == '1',
    );
  }
}

class GroupUser {
  final int id;
  final String name;

  const GroupUser({required this.id, required this.name});

  factory GroupUser.fromJson(Map<String, dynamic> json) {
    return GroupUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] as String,
    );
  }
}
