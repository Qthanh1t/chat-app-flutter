class UserInfo {
  final String id;
  final String username;
  final String avatar;

  UserInfo({
    required this.id,
    required this.username,
    required this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'],
      username: json['username'],
      avatar: json['avatar'] ?? '',
    );
  }
}

class Comment {
  final String id;
  final UserInfo user;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      user: UserInfo.fromJson(json['user']),
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Post {
  final String id;
  final UserInfo author;
  final String content;
  final List<String> images;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      author: UserInfo.fromJson(json['author']),
      content: json['content'],
      images: List<String>.from(json['images']),
      likes: List<String>.from(json['likes']),
      comments:
          (json['comments'] as List).map((c) => Comment.fromJson(c)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Post copyWith({
    String? id,
    UserInfo? author,
    String? content,
    List<String>? images,
    List<String>? likes,
    List<Comment>? comments,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      images: images ?? this.images,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
