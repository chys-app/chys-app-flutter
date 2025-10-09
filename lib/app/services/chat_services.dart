import 'dart:developer';

import 'package:chys/app/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends GetxService {
  late IO.Socket socket;

  Future<void> initSocket() async {
    final token = StorageService.getToken();
    log("🔌 Initializing socket with token: ${token?.substring(0, 20)}...");
    
    socket = IO.io('https://api.chys.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': token,
      },
    });
    
    socket.connect();
    
    socket.onConnect((_) {
      log("✅ Socket connected: ${socket.id}");
      print('Socket connected: ${socket.id}');
    });
    
    socket.onDisconnect((_) {
      log("❌ Socket disconnected");
      print('Socket disconnected');
    });

    socket.onConnectError((data) {
      log("❌ Socket connection error: $data");
      print('Connection Error: $data');
    });
    
    socket.onReconnect((_) {
      log("🔄 Socket reconnected: ${socket.id}");
      print('Socket reconnected');
    });

    socket.onError((data) {
      log("❌ Socket error: $data");
      print('Error: $data');
    });
    
    // Listen for any events to debug
    socket.onAny((event, data) {
      log("🔍 Socket event '$event': $data");
    });
  }

  void sendPrivateMessage(String receiverId, String message) {
    if (socket.connected) {
      socket.emit('private_message', {
        'receiverId': receiverId,
        'message': message,
      });
    } else {
      print('Socket not connected. Cannot send message.');
    }
  }

  void sendMediaMessage(String receiverId, String message, Map<String, dynamic> media) {
    log("🔍 Preparing to send media message...");
    log("📌 Receiver ID: $receiverId");
    log("📌 Original message text: '${message.trim()}'");
    log("📌 Incoming media map: $media");

    // 1️⃣ Check socket connection
    if (!socket.connected) {
      log("❌ Socket NOT connected — cannot send message.");
      return;
    }
    log("✅ Socket is connected. Socket ID: ${socket.id}");

    // 2️⃣ Extract media URL
    final dynamicUrl = media['url'] ?? media['secure_url'] ?? media['fileUrl'] ?? media['path'];
    if (dynamicUrl == null) {
      log("⚠️ No media URL found in the provided media map. Message will be sent without media.");
    } else {
      log("🖼 Found media URL: $dynamicUrl");
    }

    // 3️⃣ Prepare message text
    final finalMessage = message.trim().isEmpty ? "" : message.trim();
    log(finalMessage.isEmpty
        ? "ℹ️ No text message provided. Sending only media."
        : "📝 Message text prepared: '$finalMessage'");

    // 4️⃣ Build payload
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = {
      'receiverId': receiverId,
      'message': dynamicUrl,
      'messageId': messageId,
    };
    log("📦 Final payload ready to send: $payload");

    // 5️⃣ Emit socket event
    log("📤 Emitting 'private_message' event...");
    socket.emit('private_message', payload);

    // 6️⃣ Listen for server acknowledgment
    socket.once('message_sent_$messageId', (data) {
      log("✅ Server acknowledged messageId=$messageId with data: $data");
    });

    // 7️⃣ Listen for server errors
    socket.once('message_error_$messageId', (data) {
      log("❌ Server returned error for messageId=$messageId: $data");
    });

    log("🚀 Message emission process completed. Waiting for server response...");
  }

  void listenToPrivateMessages(
      Function(Map<String, dynamic>) onMessageReceived) {
    socket.on('receive_message', (data) {
      log("Private message lisner is $data");
      onMessageReceived(data);
    });
  }

  void removePrivateMessagesListener() {
    if (socket.connected) {
      socket.off('receive_message');
    } else {
      socket.off('receive_message');
    }
  }

  void disposeSocket() {
    socket.dispose();
  }
}
