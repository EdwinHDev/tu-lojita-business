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

    _socket!.onConnectError((err) => log('Business Socket connect error: $err'));
    _socket!.onError((err) => log('Business Socket error: $err'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _notificationController.close();
    disconnect();
  }
}
