class AppUser {
  final int id;
  final String name;
  final String email;
  final String? picture;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.picture,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name'] as String,
      email: json['email'] as String,
      picture: json['picture'] as String?,
    );
  }
}
