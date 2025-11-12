class User {
  final String id;
  final String username;
  final String avatar;

  User({required this.id, required this.username, required this.avatar});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      avatar: json['avatar'] ?? '',
    );
  }
}