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
import 'core/network/firebase_messaging_service.dart';
import 'core/services/order_sync_service.dart';
import 'core/services/app_lifecycle_sync_observer.dart';
import 'features/dashboard/presentation/providers/stores_notifier.dart';
import 'features/dashboard/presentation/providers/notifications_provider.dart';
import 'features/orders/presentation/providers/orders_provider.dart';
import 'features/orders/presentation/providers/dispute_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/auth/data/datasources/local_auth_data_source.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'features/auth/presentation/providers/auth_state.dart';

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
    serverClientId: Envs.googleServerClientId.isNotEmpty
        ? Envs.googleServerClientId
        : null,
  );

  // Inicializar notificaciones locales
  await NotificationHelper.init();

  // Garantizar arranque limpio sin credenciales huérfanas en instalaciones nuevas/reinstalaciones
  const storage = FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: true));
  final localAuthDataSource = LocalAuthDataSourceImpl(storage);
  await localAuthDataSource.ensureCleanInstall();

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
    ref.read(appLifecycleSyncObserverProvider);
    final syncService = ref.read(orderSyncServiceProvider);
    syncService.events.listen(_invalidateOrderData);

    ref.read(firebaseMessagingServiceProvider);
    FirebaseMessagingService.onPayloadCallback = (data) {
      ref.read(orderSyncServiceProvider).handleIncomingPayload(data);
    };
    FirebaseMessagingService.onOrderNotificationCallback = (orderId) {
      if (orderId.isNotEmpty) {
        _invalidateOrderData(OrderSyncEvent(
          orderId: orderId,
          type: 'FCM_ORDER_NOTIFICATION',
          rawData: {'orderId': orderId},
        ));
      }
    };
    _setupNotificationListener();
  }

  void _invalidateOrderData(OrderSyncEvent event) {
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    final storeIds = <String>{};
    if (event.storeId != null && event.storeId!.isNotEmpty) {
      storeIds.add(event.storeId!);
    } else {
      final stores = ref.read(storesProvider).stores;
      for (final s in stores) {
        storeIds.add(s.id);
      }
    }

    // Filtrar estrictamente sucursales autorizadas si es colaborador
    if (user != null && user.isCollaborator && !user.hasFullBranchAccess) {
      storeIds.retainWhere((sId) => user.canAccessBranch(sId));
    }

    // Si el evento no corresponde a una sucursal autorizada, evitar invalidar datos
    if (storeIds.isEmpty) return;

    if (event.orderId.isNotEmpty) {
      ref.invalidate(orderByIdProvider(event.orderId));
      ref.invalidate(storeDisputesByOrderProvider(event.orderId));
      ref.invalidate(activeStoreDisputeProvider(event.orderId));
    }

    final canViewInstallments = user?.canViewInstallments ?? true;

    for (final sId in storeIds) {
      const statuses = [null, 'PENDING', 'PARTIALLY_PAID', 'FULLY_PAID', 'CANCELLED'];
      for (final status in statuses) {
        ref.invalidate(ordersNotifierProvider((storeId: sId, status: status, hasDispute: null)));
      }
      ref.invalidate(ordersNotifierProvider((storeId: sId, status: null, hasDispute: true)));
      if (canViewInstallments) {
        ref.invalidate(storeInstallmentsProvider(sId));
        ref.invalidate(storeReceivablesProvider(sId));
      }
    }
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

          final String rawOrderId = data['orderId']?.toString() ?? '';
          final String rawTargetId = data['targetId']?.toString() ?? '';
          final String storeId = data['storeId']?.toString() ?? '';
          final String type = data['type']?.toString() ?? '';
          final String channelType = (data['channelType'] ?? '').toString();
          final String title = (data['title'] ?? '').toString();
          final String orderId = rawOrderId.isNotEmpty
              ? rawOrderId
              : (type != 'CUSTOMER_BLOCKED' && type != 'CUSTOMER_UNBLOCKED' ? rawTargetId : '');

          final authState = ref.read(authProvider);
          final user = authState is Authenticated ? authState.user : null;

          // Si es un colaborador con acceso restringido y la notificación apunta a una tienda ajena, enviar a /dashboard/notifications
          if (storeId.isNotEmpty && user != null && user.isCollaborator && !user.canAccessBranch(storeId)) {
            router.push('/dashboard/notifications');
            return;
          }

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
          } else if (type == 'MEDIATION_REQUEST' ||
              type == 'MEDIATION_RESPONSE' ||
              type == 'DISPUTE_ESCALATED') {
            if (orderId.isNotEmpty) {
              router.push('/dashboard/orders/$orderId?openDispute=true');
            } else if (storeId.isNotEmpty) {
              router.push('/dashboard/stores/$storeId/mediation-requests');
            } else {
              router.push('/dashboard/notifications');
            }
          } else if (type == 'CHAT_MESSAGE' || type == 'SUPPORT_CHAT_MESSAGE') {
            final isSupport = type == 'SUPPORT_CHAT_MESSAGE' ||
                channelType.isNotEmpty ||
                title.toLowerCase().contains('soporte');
            if (orderId.isNotEmpty) {
              if (isSupport) {
                router.push('/orders/$orderId/support-chat');
              } else {
                router.push('/dashboard/orders/$orderId/chat');
              }
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
              type == 'REFUND_REPORTED' ||
              type == 'REFUND_CONFIRMED' ||
              type.startsWith('REFUND_') ||
              (orderId.isNotEmpty &&
                  (type.startsWith('ORDER_') || type.startsWith('PAYMENT_') || type == 'GENERAL'))) {
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

    // Escuchar notificaciones de chat de soporte por socket con deduplicación
    ref.read(socketServiceProvider).supportChatNotificationStream.listen((data) {
      final orderId = data['orderId']?.toString() ?? '';
      final messageId = data['id']?.toString() ?? '${orderId}_${DateTime.now().millisecondsSinceEpoch}';
      final dedupKey = 'support_chat_$messageId';
      if (!deduplicator.shouldProcess(dedupKey)) return;

      NotificationHelper.showNotification(
        id: (orderId.hashCode + 1).abs(),
        title: data['senderName'] ?? 'Soporte Tu Lojita',
        body: data['content'] ?? '',
        payload: jsonEncode({
          'orderId': orderId,
          'targetId': orderId,
          'type': 'SUPPORT_CHAT_MESSAGE',
          'channelType': data['channelType'] ?? 'DISPUTE_MERCHANT_SUPPORT',
        }),
      );
    });

    // Escuchar notificaciones generales por socket (pedidos, pagos, cuotas, reclamos)
    ref.read(socketServiceProvider).notificationsStream.listen((data) {
      ref.invalidate(notificationsProvider);

      // Despachar al bus unificado de sincronización
      ref.read(orderSyncServiceProvider).handleIncomingPayload(data);

      final rawId =
          data['id']?.toString() ?? data['notificationId']?.toString() ?? '';
      if (rawId.isNotEmpty && !deduplicator.shouldProcess(rawId)) {
        return; // Suprimido: ya procesado por otro canal
      }

      final id =
          data['id']?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.hashCode;
      final title = data['title'] ?? 'Nueva notificación';
      final body = data['body'] ?? '';
      final targetId =
          data['targetId']?.toString() ?? data['orderId']?.toString() ?? '';
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

    // Escuchar actualizaciones de disputas en tiempo real (Task 4.3)
    ref.read(socketServiceProvider).disputeUpdatedStream.listen((data) {
      final orderId = data['orderId']?.toString() ??
          data['dispute']?['orderId']?.toString() ??
          '';
      if (orderId.isNotEmpty) {
        ref.invalidate(orderByIdProvider(orderId));
        ref.invalidate(storeDisputesByOrderProvider(orderId));
        ref.invalidate(activeStoreDisputeProvider(orderId));
      }
      ref.invalidate(ordersNotifierProvider);
      ref.invalidate(notificationsProvider);
      ref.read(orderSyncServiceProvider).handleIncomingPayload({
        'orderId': orderId,
        'type': 'DISPUTE_UPDATED',
        ...data,
      });
    });

    // Escuchar expulsión disciplinaria en tiempo real por WebSocket
    ref.read(socketServiceProvider).accountSuspendedStream.listen((data) async {
      final reason = data['reason']?.toString() ?? 'Tu cuenta comercial ha sido suspendida.';
      final suspendedUntil = data['suspendedUntil']?.toString();
      final isPermanent = data['type'] == 'PERMANENT' || suspendedUntil == null;

      ref.read(socketServiceProvider).disconnect();

      await ref.read(authProvider.notifier).handleAccountSuspended(
        reason: reason,
        suspendedUntil: suspendedUntil,
        isPermanent: isPermanent,
      );

      final router = ref.read(routerProvider);
      router.go(
        '/account-suspended',
        extra: {
          'suspendedUntil': suspendedUntil,
          'reason': reason,
        },
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
