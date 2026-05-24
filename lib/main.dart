import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/envs.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/utils/notification_helper.dart';
import 'core/network/background_service_manager.dart';
import 'features/dashboard/presentation/providers/notifications_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Envs.init();

  // Inicializar notificaciones locales
  await NotificationHelper.init();

  // Inicializar servicio de fondo para monitoreo de pedidos
  await initializeBackgroundService();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    NotificationHelper.onNotificationClick.stream.listen((payload) {
      final router = ref.read(routerProvider);
      if (payload != null && payload.isNotEmpty) {
        try {
          final data = jsonDecode(payload);
          final String orderId = data['orderId'] ?? '';
          final String type = data['type'] ?? '';

          if (type == 'CHAT_MESSAGE') {
            router.push('/dashboard/orders/$orderId/chat');
          } else {
            router.push('/dashboard/orders/$orderId');
          }
        } catch (e) {
          // Retrocompatibilidad
          router.push('/dashboard/orders/$payload');
        }
      } else {
        router.push('/dashboard/notifications');
      }
    });

    // Escuchar notificaciones de chat por socket
    ref.read(socketServiceProvider).chatNotificationStream.listen((data) {
      NotificationHelper.showNotification(
        id: data['orderId'].hashCode,
        title: data['senderName'] ?? 'Nuevo mensaje',
        body: data['content'] ?? '',
        payload: jsonEncode({
          'orderId': data['orderId'],
          'type': 'CHAT_MESSAGE',
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Tu Lojita Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
