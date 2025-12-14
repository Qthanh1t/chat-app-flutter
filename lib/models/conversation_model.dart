import 'user_model.dart';

class Conversation {
  final String id;
  final String type; // 'private' hoặc 'group'
  final String? groupName;
  final List<User> participants;
  final dynamic lastMessage; // Có thể là Message Model hoặc Map
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.type,
    this.groupName,
    required this.participants,
    this.lastMessage,
    required this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'],
      type: json['type'],
      groupName: json['groupName'],
      participants:
          (json['participants'] as List).map((p) => User.fromJson(p)).toList(),
      lastMessage: json['lastMessage'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
    );
  }

  // --- Helper Getters (Rất quan trọng) ---

  // Lấy tên hiển thị cho Conversation
  String getDisplayName(String myUserId) {
    if (type == 'group') {
      return groupName ?? 'Nhóm không tên';
    } else {
      // Trong chat 1-1, tìm người kia
      final otherUser = participants.firstWhere(
        (user) => user.id != myUserId,
        orElse: () => participants.first, // Fallback
      );
      return otherUser.username;
    }
  }

  // Lấy avatar hiển thị cho Conversation
  String getDisplayAvatar(String myUserId) {
    if (type == 'group') {
      return ''; // Hoặc trả về một avatar nhóm mặc định
    } else {
      final otherUser = participants.firstWhere(
        (user) => user.id != myUserId,
        orElse: () => participants.first,
      );
      return otherUser.avatar;
    }
  }
}
