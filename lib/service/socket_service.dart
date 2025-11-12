import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';
import '../constants/api_constants.dart';

class SocketService {
  late IO.Socket socket;
  Function(dynamic)? _onMessageCallback;
  final box = Hive.box("chat_app");
  void connect() {
    final token = box.get("token");
    final userId = box.get("userId");
    socket = IO.io(socketUrl, <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
      "extraHeaders": {"Authorization": "Bearer $token"},
      "reconnection": true,
      "reconnectionAttempts": 5,
      "reconnectionDelay": 2000
    });
    socket.connect();
    socket.onConnect((_) {
      print("🔌 Kết nối Socket thành công");
      // Join room với userId
      socket.emit("join", userId);
    });
    socket.onDisconnect((_) {
      print("❌ Socket đã ngắt kết nối");
    });
  }

  void sendMessage(String conversationId, String content, String type) {
    final senderId = box.get("userId");
    socket.emit("send_message", {
      "senderId": senderId,
      "conversationId": conversationId,
      "content": content,
      "type": type
    });
  }

  void onMessage(Function(dynamic) callback) {
    socket.on("receive_message", (data) {
      callback(data);
    });
  }

  void offMessage() {
    _onMessageCallback = null;
  }
}
