import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/envs.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/utils/notification_helper.dart';
import 'core/network/background_service_manager.dart';

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
        router.push('/dashboard/orders/$payload');
      } else {
        router.push('/dashboard/notifications');
      }
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
