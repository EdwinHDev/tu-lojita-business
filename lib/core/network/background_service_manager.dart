import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Crear los canales de notificaciones para Android antes de configurar el servicio
  const AndroidNotificationChannel businessChannel = AndroidNotificationChannel(
    'business_notifications',
    'Business Notifications',
    description: 'Canal para notificaciones de pedidos y pagos',
    importance: Importance.max,
  );

  const AndroidNotificationChannel bgServiceChannel = AndroidNotificationChannel(
    'bg_service_channel',
    'Servicio en segundo plano',
    description: 'Mantiene la conexión activa para recibir notificaciones',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidImpl?.createNotificationChannel(businessChannel);
  await androidImpl?.createNotificationChannel(bgServiceChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'bg_service_channel',
      initialNotificationTitle: 'Tu Lojita Business',
      initialNotificationContent: 'Servicio activo para notificaciones',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  final baseUrl = Envs.apiBaseUrl;
  const storage = FlutterSecureStorage();
  const accessTokenKey = 'access_token';

  // Inicializar notificaciones locales DENTRO del isolate
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  io.Socket? socket;
  Timer? reconnectTimer;

  Future<void> connectSocket() async {
    // Si ya está conectado, no hacemos nada
    if (socket != null && socket!.connected) return;

    final token = await storage.read(key: accessTokenKey);
    final socketUrl = baseUrl.replaceAll('/api/v1', '');

    if (token == null) {
      debugPrint('BackgroundService: No token found, waiting...');
      return;
    }

    // Si ya existe pero no está conectado, lo desconectamos para limpiar
    if (socket != null) {
      socket!.dispose();
    }

    socket = io.io(
      '$socketUrl/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('BackgroundService: Connected to socket');
    });

    socket!.onDisconnect((_) {
      debugPrint('BackgroundService: Disconnected from socket');
    });

    socket!.on('new_notification', (data) {
      flutterLocalNotificationsPlugin.show(
        data['id'].hashCode,
        data['title'],
        data['body'],
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'business_notifications',
            'Business Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
            color: Color(0xFF4F46E5),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
          ),
        ),
        payload: data['targetId'],
      );
    });
  }

  // Intentar conectar inicialmente
  connectSocket();

  // Reintentar cada 30 segundos si no está conectado
  reconnectTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    if (socket == null || !socket!.connected) {
      debugPrint('BackgroundService: Attempting to reconnect...');
      connectSocket();
    }
  });

  service.on('stopService').listen((event) {
    reconnectTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    service.stopSelf();
  });
}
