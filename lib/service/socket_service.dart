import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';

class SocketService {
  late IO.Socket socket;
  final box = Hive.box("chat_app");
  void connect() {
    final token = box.get("token");
    final userId = box.get("userId");
    socket = IO.io("http://10.0.2.2:5000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
      "extraHeaders": {"Authorization": "Bearer $token"},
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

  void sendMessage(String receiverId, String content, {String type = "text"}) {
    final senderId = box.get("userId");
    socket.emit("send_message", {
      "senderId": senderId,
      "receiverId": receiverId,
      "content": content,
      "type": type
    });
  }

  void sendImage(String receiverId, String base64Image) {
    final senderId = box.get("userId");
    socket.emit("send_message", {
      "senderId": senderId,
      "receiverId": receiverId,
      "content": base64Image,
      "type": "image"
    });
  }

  void onMessage(Function(dynamic) callback) {
    socket.on("receive_message", (data) {
      callback(data);
    });
  }
}
