import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'core/config/envs.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/utils/notification_helper.dart';
import 'core/network/background_service_manager.dart';
import 'core/network/notification_deduplicator.dart';
import 'features/dashboard/presentation/providers/notifications_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar iconos oscuros en la barra de estado y de navegación (Modo Claro)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Envs.init();

  // Inicialización global obligatoria de Google Sign-In (Credential Manager)
  await GoogleSignIn.instance.initialize(
    serverClientId: Envs.googleServerClientId.isNotEmpty ? Envs.googleServerClientId : null,
  );

  // Inicializar notificaciones locales
  await NotificationHelper.init();

  // Detener de forma limpia cualquier servicio residual en segundo plano
  await stopBackgroundServiceIfRunning();

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
    ref.read(firebaseMessagingServiceProvider);
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    NotificationHelper.onNotificationClick.stream.listen((payload) {
      final router = ref.read(routerProvider);
      if (payload != null && payload.isNotEmpty) {
        try {
          final data = jsonDecode(payload);
          final notificationId = data['notificationId'] ?? data['id'];
          if (notificationId != null && notificationId.toString().isNotEmpty) {
            ref
                .read(notificationRepositoryProvider)
                .markAsRead(notificationId.toString())
                .then((_) {
                  ref.invalidate(notificationsProvider);
                })
                .catchError((_) {});
          }

          final String orderId = data['orderId']?.toString() ?? '';
          final String storeId = data['storeId']?.toString() ?? '';
          final String type = data['type']?.toString() ?? '';

          if (type == 'DIVISION_UP') {
            router.push('/dashboard/ranking/celebration', extra: data);
          } else if (type == 'DIVISION_DOWN') {
            router.push('/dashboard/ranking/division-down', extra: data);
          } else if (type == 'ACHIEVEMENT_UNLOCKED') {
            router.push('/dashboard/ranking/achievement-unlocked', extra: data);
          } else if (type == 'STORE_FLAGGED') {
            router.push('/dashboard/ranking/flagged', extra: data);
          } else if (type == 'WEEKLY_RANKING_SUMMARY') {
            if (storeId.isNotEmpty) {
              router.push('/dashboard/stores/$storeId/ranking');
            } else {
              router.push('/dashboard/notifications');
            }
          } else if (type == 'MEDIATION_REQUEST' || type == 'MEDIATION_RESPONSE') {
            if (storeId.isNotEmpty) {
              router.push('/dashboard/stores/$storeId/mediation-requests');
            } else if (orderId.isNotEmpty) {
              router.push('/dashboard/orders/$orderId?openDispute=true');
            } else {
              router.push('/dashboard/notifications');
            }
          } else if (type == 'CHAT_MESSAGE') {
            if (orderId.isNotEmpty) {
              router.push('/dashboard/orders/$orderId/chat');
            } else {
              router.push('/dashboard/notifications');
            }
          } else if (type == 'REPORT_RESOLUTION' || type == 'CHAT_PENALTY') {
            router.push('/dashboard/notifications');
          } else if (type == 'BUYER_REVIEW_PROMPT' ||
              type == 'ORDER_REVIEW_RECEIVED') {
            if (orderId.isNotEmpty) {
              router.push('/dashboard/orders/$orderId');
            } else {
              router.push('/dashboard/notifications');
            }
          } else if (type == 'ORDER_CREATED' ||
              type == 'ORDER_STATUS_CHANGED' ||
              type == 'PAYMENT_REPORTED' ||
              type == 'PAYMENT_APPROVED' ||
              type == 'PAYMENT_REJECTED' ||
              (orderId.isNotEmpty &&
                  (type.startsWith('ORDER_') || type.startsWith('PAYMENT_')))) {
            if (orderId.isNotEmpty) {
              router.push('/dashboard/orders/$orderId');
            } else {
              router.push('/dashboard/notifications');
            }
          } else {
            router.push('/dashboard/notifications');
          }
        } catch (e) {
          router.push('/dashboard/notifications');
        }
      } else {
        router.push('/dashboard/notifications');
      }
    });

    final deduplicator = NotificationDeduplicator();

    // Escuchar notificaciones de chat por socket con deduplicación
    ref.read(socketServiceProvider).chatNotificationStream.listen((data) {
      final orderId = data['orderId']?.toString() ?? '';
      final messageId = data['id']?.toString() ?? orderId;
      final dedupKey = 'chat_$messageId';
      if (!deduplicator.shouldProcess(dedupKey)) return;

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

    // Escuchar notificaciones generales por socket (pedidos, pagos, cuotas, reclamos)
    ref.read(socketServiceProvider).notificationsStream.listen((data) {
      ref.invalidate(notificationsProvider);

      final rawId =
          data['id']?.toString() ?? data['notificationId']?.toString() ?? '';
      if (rawId.isNotEmpty && !deduplicator.shouldProcess(rawId)) {
        return; // Suprimido: ya procesado por otro canal
      }

      final id =
          data['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode;
      final title = data['title'] ?? 'Nueva notificación';
      final body = data['body'] ?? '';
      final targetId = data['targetId']?.toString() ?? data['orderId']?.toString() ?? '';
      final orderId = data['orderId']?.toString() ?? '';
      final storeId = data['storeId']?.toString() ?? '';
      final type = data['type'] ?? '';

      NotificationHelper.showNotification(
        id: id,
        title: title,
        body: body,
        payload: jsonEncode({
          'orderId': orderId,
          'targetId': targetId,
          'storeId': storeId,
          'type': type,
          'notificationId': rawId,
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Tu Lojita - Empresa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('es', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
