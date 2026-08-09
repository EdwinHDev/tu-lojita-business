import 'dart:async';
import 'dart:developer';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';

class SocketService {
  final LocalAuthDataSource _localAuthDataSource;
  io.Socket? _socket;
  final List<void Function()> _pendingActions = [];
  String? _currentChatOrderId;
  bool _isReconnecting = false;
  
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

  bool get isConnected => _socket != null && _socket!.connected;

  Future<void> init() async {
    if (_socket != null && _socket!.connected) return;

    var token = await _localAuthDataSource.getAccessToken();
    final baseUrl = Envs.apiBaseUrl;
    final socketUrl = baseUrl.replaceAll('/api/v1', '');

    _socket = io.io(
      '$socketUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(15)
          .setTimeout(10000)
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      log('Business Socket connected to /notifications namespace');
      _isReconnecting = false;
      
      // Auto-rejoin de chat activo en caso de reconexión
      if (_currentChatOrderId != null) {
        log('Business Auto-rejoining chat room: $_currentChatOrderId');
        _socket!.emit('join_chat', {'orderId': _currentChatOrderId});
      }

      // Procesar y vaciar cola de acciones pendientes
      while (_pendingActions.isNotEmpty) {
        final action = _pendingActions.removeAt(0);
        try {
          action();
        } catch (e) {
          log('Business Error running pending socket action: $e');
        }
      }
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

    _socket!.on('exception', (data) {
      log('Business Socket exception event: $data');
      _handleConnectionError(data);
    });

    _socket!.onConnectError((err) {
      log('Business Socket connect error: $err');
      _handleConnectionError(err);
    });

    _socket!.onError((err) {
      log('Business Socket error: $err');
      _handleConnectionError(err);
    });
  }

  Future<void> _handleConnectionError(dynamic err) async {
    final errStr = err.toString().toLowerCase();
    if (errStr.contains('unauthorized') || errStr.contains('jwt') || errStr.contains('token') || errStr.contains('forbidden')) {
      if (!_isReconnecting) {
        _isReconnecting = true;
        log('Business Auth error detected on socket. Triggering reconnectWithFreshToken...');
        await reconnectWithFreshToken();
      }
    }
  }

  Future<void> reconnectWithFreshToken() async {
    log('Business Reconnecting socket with fresh token...');
    try {
      final refreshToken = await _localAuthDataSource.getRefreshToken();
      if (refreshToken != null) {
        final dio = Dio();
        final baseUrl = Envs.apiBaseUrl;
        final response = await dio.get(
          '$baseUrl/auth/refresh',
          options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
        );
        if (response.statusCode == 200 && response.data != null) {
          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];
          if (newAccessToken != null && newRefreshToken != null) {
            await _localAuthDataSource.saveAccessToken(newAccessToken);
            await _localAuthDataSource.saveRefreshToken(newRefreshToken);
            log('Business Tokens refreshed successfully for WebSocket');
          }
        }
      }
    } catch (e) {
      log('Business Failed to refresh token during socket reconnect: $e');
    }

    _socket?.dispose();
    _socket = null;
    _isReconnecting = false;
    await init();
  }

  void _emitOrQueue(String event, Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      log('Business Socket not connected. Queueing event: $event with data: $data');
      _pendingActions.add(() {
        _socket?.emit(event, data);
      });
    }
  }

  void joinChat(String orderId) {
    _currentChatOrderId = orderId;
    _emitOrQueue('join_chat', {'orderId': orderId});
  }

  void leaveChat(String orderId) {
    if (_currentChatOrderId == orderId) {
      _currentChatOrderId = null;
    }
    _emitOrQueue('leave_chat', {'orderId': orderId});
  }

  void sendMessage(String orderId, String content) {
    _emitOrQueue('send_message', {
      'orderId': orderId,
      'content': content,
    });
  }

  Future<Map<String, dynamic>> sendMessageWithAck(
    String orderId,
    String content, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    final data = {'orderId': orderId, 'content': content};

    if (_socket == null || !_socket!.connected) {
      await reconnectWithFreshToken();
    }

    if (_socket != null && _socket!.connected) {
      try {
        _socket!.emitWithAck('send_message', data, ack: (response) {
          if (!completer.isCompleted) {
            if (response is Map) {
              completer.complete(Map<String, dynamic>.from(response));
            } else {
              completer.complete({'success': true});
            }
          }
        });
      } catch (e) {
        log('Business Error in emitWithAck: $e');
        if (!completer.isCompleted) {
          completer.complete({'success': false, 'error': e.toString()});
        }
      }
    } else {
      if (!completer.isCompleted) {
        completer.complete({'success': false, 'error': 'NOT_CONNECTED'});
      }
    }

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        log('Business sendMessageWithAck timeout for order $orderId');
        return {'success': false, 'error': 'TIMEOUT'};
      },
    );
  }

  void emitTyping(String orderId, bool isTyping) {
    _emitOrQueue('typing', {'orderId': orderId, 'isTyping': isTyping});
  }

  void markMessagesRead(String orderId) {
    _emitOrQueue('mark_messages_read', {'orderId': orderId});
  }

  void markMessagesDelivered(String orderId) {
    _emitOrQueue('mark_messages_delivered', {'orderId': orderId});
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
