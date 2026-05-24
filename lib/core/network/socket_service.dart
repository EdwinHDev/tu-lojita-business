import 'dart:async';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';

class SocketService {
  final LocalAuthDataSource _localAuthDataSource;
  io.Socket? _socket;
  
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationsStream => _notificationController.stream;

  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  final _chatHistoryController = StreamController<List<dynamic>>.broadcast();
  Stream<List<dynamic>> get chatHistoryStream => _chatHistoryController.stream;

  final _chatNotificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatNotificationStream => _chatNotificationController.stream;

  final _chatTypingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatTypingStream => _chatTypingController.stream;

  final _chatMessagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessagesReadStream => _chatMessagesReadController.stream;

  final _chatMessagesDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessagesDeliveredStream => _chatMessagesDeliveredController.stream;

  final _chatMessagesUnreadController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatMessagesUnreadStream => _chatMessagesUnreadController.stream;

  final _chatClosedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatClosedStream => _chatClosedController.stream;

  SocketService(this._localAuthDataSource);

  void init() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _localAuthDataSource.getAccessToken();
    final baseUrl = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:4500/api/v1';
    final socketUrl = baseUrl.replaceAll('/api/v1', '');

    _socket = io.io(
      '$socketUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      log('Business Socket connected to /notifications namespace');
    });

    _socket!.onDisconnect((_) {
      log('Business Socket disconnected from /notifications');
    });

    _socket!.on('new_notification', (data) {
      log('Business New notification received: $data');
      _notificationController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_chat_message', (data) {
      log('New chat message received: $data');
      _chatController.add(Map<String, dynamic>.from(data));
      // Si la app está abierta y el mensaje llega, el dispositivo lo recibió → marcar como entregado.
      // El servidor filtra: solo marca mensajes donde sender != yo, así que es seguro emitirlo siempre.
      final orderId = data['orderId'] ?? data['order']?['id'];
      if (orderId != null) {
        _socket?.emit('mark_messages_delivered', {'orderId': orderId});
      }
    });

    _socket!.on('chat_history', (data) {
      log('Business Chat history received: $data');
      _chatHistoryController.add(List<dynamic>.from(data));
    });

    _socket!.on('chat_notification', (data) {
      log('Business Chat notification received: $data');
      _chatNotificationController.add(Map<String, dynamic>.from(data));
      // chat_notification siempre llega al destinatario (sala user_ID).
      // Aunque no tenga el chat abierto, confirmamos la entrega del mensaje.
      final orderId = data['orderId'];
      if (orderId != null) {
        _socket?.emit('mark_messages_delivered', {'orderId': orderId});
      }
    });

    _socket!.on('typing', (data) {
      _chatTypingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('messages_read', (data) {
      log('Business Messages read received: $data');
      _chatMessagesReadController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('messages_delivered', (data) {
      log('Business Messages delivered received: $data');
      _chatMessagesDeliveredController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('messages_unread', (data) {
      log('Business Messages unread received: $data');
      _chatMessagesUnreadController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chat_closed', (data) {
      log('Business Chat closed event received: $data');
      _chatClosedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onConnectError((err) => log('Business Socket connect error: $err'));
    _socket!.onError((err) => log('Business Socket error: $err'));
  }

  void joinChat(String orderId) {
    _socket?.emit('join_chat', {'orderId': orderId});
  }

  void leaveChat(String orderId) {
    _socket?.emit('leave_chat', {'orderId': orderId});
  }

  void sendMessage(String orderId, String content) {
    _socket?.emit('send_message', {
      'orderId': orderId,
      'content': content,
    });
  }

  void emitTyping(String orderId, bool isTyping) {
    _socket?.emit('typing', {'orderId': orderId, 'isTyping': isTyping});
  }

  void markMessagesRead(String orderId) {
    _socket?.emit('mark_messages_read', {'orderId': orderId});
  }

  void markMessagesDelivered(String orderId) {
    _socket?.emit('mark_messages_delivered', {'orderId': orderId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _notificationController.close();
    _chatController.close();
    _chatHistoryController.close();
    _chatNotificationController.close();
    _chatTypingController.close();
    _chatMessagesReadController.close();
    _chatMessagesDeliveredController.close();
    _chatMessagesUnreadController.close();
    _chatClosedController.close();
    disconnect();
  }
}
