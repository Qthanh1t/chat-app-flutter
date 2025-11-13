// service/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';
import '../constants/api_constants.dart';

class SocketService {
  late IO.Socket socket;
  final box = Hive.box("chat_app");

  // --- Logic Singleton ---
  static final SocketService _instance = SocketService._internal();

  // Constructor factory sẽ trả về thể hiện _instance duy nhất
  factory SocketService() {
    return _instance;
  }

  // Constructor nội bộ, chỉ chạy 1 lần
  SocketService._internal() {
    // Khởi tạo socket nhưng chưa kết nối
    final token = box.get("token");
    socket = IO.io(socketUrl, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false, // Quan trọng: không tự động kết nối
      "extraHeaders": {"Authorization": "Bearer $token"},
      "reconnection": true,
      "reconnectionAttempts": 5,
      "reconnectionDelay": 2000
    });

    _setupListeners();
  }

  // --- Kết thúc Logic Singleton ---

  // Kết nối (chỉ gọi 1 LẦN khi app khởi động)
  void connect() {
    if (socket.connected) {
      print("🔌 Socket đã kết nối.");
      return;
    }
    socket.connect();
  }

  // Ngắt kết nối (khi logout)
  void disconnect() {
    socket.disconnect();
  }

  // Thiết lập các listener (chỉ chạy 1 lần)
  void _setupListeners() {
    final userId = box.get("userId");

    socket.onConnect((_) {
      print("🔌 Kết nối Socket thành công");
      // Join room cá nhân VÀ tất cả các room conversation cũ
      socket.emit("join", userId);
    });
    socket.onDisconnect((_) {
      print("❌ Socket đã ngắt kết nối");
    });
  }

  // --- Các hàm Public ---

  // Gửi tin nhắn (đã refactor)
  void sendMessage(String conversationId, String content, String type) {
    final senderId = box.get("userId");
    socket.emit("send_message", {
      "senderId": senderId,
      "conversationId": conversationId,
      "content": content,
      "type": type
    });
  }

  // HÀM MỚI: Yêu cầu join room
  void joinConversationRoom(String conversationId) {
    socket.emit("join_conversation_room", conversationId);
    print("🚀 Yêu cầu join room: $conversationId");
  }

  // Đăng ký listener (để ChatPage sử dụng)
  void onMessage(Function(dynamic) callback) {
    socket.on("receive_message", (data) {
      callback(data);
    });
  }

  // Hủy đăng ký listener
  void offMessage(Function(dynamic) callback) {
    // Tắt một listener cụ thể
    socket.off("receive_message", callback);
  }
}
