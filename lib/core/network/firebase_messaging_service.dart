import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/network/notification_deduplicator.dart';
import 'package:tu_lojita_business/core/utils/notification_helper.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/utils/achievement_image_helper.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/settings/store_health_sheet.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/chat_penalty_explanation_modal.dart';
import 'package:tu_lojita_business/features/reports/presentation/widgets/report_detail_sheet.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('Business FCM Background message: ${message.messageId}');
}

class FirebaseMessagingService {
  final Dio _dio;
  final GoRouter Function() _getRouter;
  final void Function(String notificationId)? onMarkAsRead;
  final VoidCallback? onNotificationReceived;
  final bool Function(String permission)? hasPermission;
  final bool Function(String storeId)? canAccessBranch;
  final String? Function()? getFallbackStoreId;
  final Future<void> Function()? ensureStoresLoaded;
  final NotificationDeduplicator _deduplicator = NotificationDeduplicator();
  static void Function(String orderId)? onOrderNotificationCallback;
  static void Function(Map<String, dynamic> data)? onPayloadCallback;
  static void Function(String notificationId)? onActiveChatNotificationCallback;
  static bool Function(String orderId, {bool isSupport})? isViewingChatCallback;

  static FirebaseMessagingService? _activeInstance;
  static Map<String, dynamic>? _pendingInitialNotification;
  static bool _isAppReadyForDeepLinks = false;
  static bool _listenersRegistered = false;
  static bool _initialMessageChecked = false;
  static bool _tokenRefreshRegistered = false;
  static final Map<String, DateTime> _recentConsumedTapKeys = {};

  @visibleForTesting
  static String Function()? debugCurrentPathOverride;
  @visibleForTesting
  static void Function(String route, Object? extra)? debugPushRouteOverride;
  @visibleForTesting
  static void Function(String modalType, Map<String, dynamic> details)?
      debugModalOverride;

  FirebaseMessagingService(
    this._dio,
    this._getRouter, {
    this.onMarkAsRead,
    this.onNotificationReceived,
    this.hasPermission,
    this.canAccessBranch,
    this.getFallbackStoreId,
    this.ensureStoresLoaded,
  }) {
    _activeInstance = this;
  }

  @visibleForTesting
  static void resetForTesting() {
    _pendingInitialNotification = null;
    _isAppReadyForDeepLinks = false;
    _recentConsumedTapKeys.clear();
    debugCurrentPathOverride = null;
    debugPushRouteOverride = null;
    debugModalOverride = null;
  }

  @visibleForTesting
  static Map<String, dynamic>? get pendingNotificationForTest =>
      _pendingInitialNotification == null
          ? null
          : Map<String, dynamic>.from(_pendingInitialNotification!);

  static void resetReadinessOnLogout() {
    _isAppReadyForDeepLinks = false;
  }

  static String _resolveDefaultTitle(String type) {
    switch (type) {
      case 'ORDER_CREATED':
      case 'ORDER_STATUS_CHANGED':
        return 'Actualización de Pedido';
      case 'PAYMENT_REPORTED':
      case 'PAYMENT_APPROVED':
      case 'PAYMENT_REJECTED':
        return 'Actualización de Pago';
      case 'CHAT_MESSAGE':
      case 'SUPPORT_CHAT_MESSAGE':
        return 'Nuevo Mensaje';
      case 'MEDIATION_REQUEST':
      case 'MEDIATION_RESPONSE':
        return 'Mediación de Tienda';
      case 'ORDER_REVIEW_RECEIVED':
        return 'Nueva Reseña Recibida';
      default:
        return 'Tu Lojita Comercio';
    }
  }

  static String _resolveDefaultBody(String type) {
    switch (type) {
      case 'ORDER_CREATED':
        return 'Has recibido un nuevo pedido en tu comercio.';
      case 'ORDER_STATUS_CHANGED':
        return 'El estado de un pedido ha sido actualizado.';
      case 'PAYMENT_REPORTED':
        return 'Se ha reportado un nuevo pago para verificación.';
      case 'PAYMENT_APPROVED':
        return 'Un pago ha sido aprobado exitosamente.';
      case 'PAYMENT_REJECTED':
        return 'Un comprobante de pago ha sido rechazado.';
      case 'CHAT_MESSAGE':
        return 'Has recibido un nuevo mensaje de un cliente.';
      case 'SUPPORT_CHAT_MESSAGE':
        return 'Has recibido un mensaje del equipo de soporte.';
      case 'MEDIATION_REQUEST':
      case 'MEDIATION_RESPONSE':
        return 'Tienes una actualización en el caso de mediación.';
      case 'ORDER_REVIEW_RECEIVED':
        return 'Un cliente ha calificado su experiencia en tu tienda.';
      default:
        return 'Tienes una nueva notificación en tu comercio.';
    }
  }

  static Map<String, dynamic> _extractMessageData(RemoteMessage message) {
    final map = Map<String, dynamic>.from(message.data);
    if (message.messageId != null && message.messageId!.isNotEmpty) {
      map.putIfAbsent('messageId', () => message.messageId);
    }
    final type = map['type']?.toString() ?? '';
    final notifTitle = message.notification?.title?.trim();
    if ((map['title'] == null || map['title'].toString().trim().isEmpty) &&
        notifTitle != null &&
        notifTitle.isNotEmpty) {
      map['title'] = notifTitle;
    }
    final notifBody = message.notification?.body?.trim();
    if ((map['body'] == null || map['body'].toString().trim().isEmpty) &&
        notifBody != null &&
        notifBody.isNotEmpty) {
      map['body'] = notifBody;
    }

    if (map['title'] == null || map['title'].toString().trim().isEmpty) {
      map['title'] = _resolveDefaultTitle(type);
    }
    if (map['body'] == null || map['body'].toString().trim().isEmpty) {
      map['body'] = _resolveDefaultBody(type);
    }
    return map;
  }

  @visibleForTesting
  static Map<String, dynamic> extractMessageDataForTest(RemoteMessage message) {
    return _extractMessageData(message);
  }

  static bool isModerationNotice({
    required String type,
    required String title,
    required String body,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    return type == 'CHAT_PENALTY' ||
        (type == 'GENERAL' &&
            (lowerTitle.contains('moderación') ||
                lowerTitle.contains('suspensión') ||
                lowerTitle.contains('advertencia') ||
                lowerTitle.contains('acceso al chat restaurado') ||
                body.contains('Mensajes citados como evidencia') ||
                lowerBody.contains('acceso al chat de órdenes')));
  }

  Future<void> init() async {
    _activeInstance = this;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (!_listenersRegistered) {
        _listenersRegistered = true;

        // 1. Foreground message listener registrado inmediatamente sin bloqueos de red
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          (_activeInstance ?? this)._handleForegroundMessage(message);
        });

        // 2. Segundo plano (Warm start) registrado antes de solicitar permisos o red
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          (_activeInstance ?? this)
              .queueOrNavigate(_extractMessageData(message));
        });
      }

      // 3. Captura prioritaria de notificación en arranque en frío (Cold start - FCM o local)
      if (!_initialMessageChecked) {
        _initialMessageChecked = true;
        await _captureInitialLaunchNotification();
      }

      // 4. Permisos y registro remoto de token en segundo plano no bloqueante
      unawaited(_initPermissionsAndToken());
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging in Business app: $e');
    }
  }

  Future<void> _captureInitialLaunchNotification() async {
    if (NotificationHelper.pendingLaunchPayload != null &&
        NotificationHelper.pendingLaunchPayload!.isNotEmpty) {
      try {
        final decoded = jsonDecode(NotificationHelper.pendingLaunchPayload!);
        if (decoded is Map) {
          _pendingInitialNotification = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('Error decoding pending business launch payload: $e');
      } finally {
        NotificationHelper.pendingLaunchPayload = null;
      }
    }

    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        queueOrNavigate(_extractMessageData(initialMessage));
      }
    } catch (e) {
      debugPrint('Error getting initial Business FCM message: $e');
    }
  }

  Future<void> _initPermissionsAndToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
          'Business FCM Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Business FCM requestPermission warning: $e');
    }

    await registerDeviceToken();

    if (!_tokenRefreshRegistered) {
      _tokenRefreshRegistered = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        (_activeInstance ?? this)._sendTokenToBackend(newToken);
      });
    }
  }

  String _currentRouterPath() {
    if (debugCurrentPathOverride != null) {
      return debugCurrentPathOverride!();
    }
    try {
      return _getRouter().routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      return '';
    }
  }

  static bool _isOnNonDashboardTransientRoute(String path) {
    return path.isEmpty ||
        path == '/splash' ||
        path == '/onboarding' ||
        path == '/login' ||
        path == '/register' ||
        path == '/verify-otp' ||
        path == '/forgot-password' ||
        path == '/reset-password' ||
        path == '/onboarding/company' ||
        path == '/subscription/paywall' ||
        path == '/subscription/pending' ||
        path == '/subscription/rejected' ||
        path == '/dashboard/store-setup-wizard';
  }

  static bool _shouldConsumeTap(Map<String, dynamic> data) {
    final now = DateTime.now();
    _recentConsumedTapKeys.removeWhere(
      (_, ts) => now.difference(ts).inMilliseconds > 5000,
    );

    final uniqueId = (data['messageId'] ??
            data['notificationId'] ??
            data['id'] ??
            '')
        .toString()
        .trim();
    final type = (data['type'] ?? '').toString().trim();
    final orderId = (data['orderId'] ?? '').toString().trim();
    final targetId = (data['targetId'] ?? '').toString().trim();
    final storeId = (data['storeId'] ?? '').toString().trim();
    final title = (data['title'] ?? '').toString().trim();

    final key = uniqueId.isNotEmpty
        ? 'id:$uniqueId|$type|$orderId|$targetId'
        : 'anon:$type|$orderId|$targetId|$storeId|$title';
    final ttlMs = uniqueId.isNotEmpty ? 4000 : 1500;

    final last = _recentConsumedTapKeys[key];
    if (last != null && now.difference(last).inMilliseconds < ttlMs) {
      debugPrint('Business duplicate notification tap suppressed: $key');
      return false;
    }
    _recentConsumedTapKeys[key] = now;
    return true;
  }

  void queueOrNavigate(Map<String, dynamic> data) {
    final currentPath = _currentRouterPath();

    if (!_isAppReadyForDeepLinks ||
        _isOnNonDashboardTransientRoute(currentPath)) {
      _pendingInitialNotification = Map<String, dynamic>.from(data);
      return;
    }

    if (!_shouldConsumeTap(data)) return;
    unawaited(handleNotificationNavigation(data));
  }

  void markAppReadyAndConsumePendingNotification() {
    _isAppReadyForDeepLinks = true;

    if (_pendingInitialNotification == null &&
        NotificationHelper.pendingLaunchPayload != null &&
        NotificationHelper.pendingLaunchPayload!.isNotEmpty) {
      try {
        final decoded = jsonDecode(NotificationHelper.pendingLaunchPayload!);
        if (decoded is Map) {
          _pendingInitialNotification = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
      } finally {
        NotificationHelper.pendingLaunchPayload = null;
      }
    }

    final pending = _pendingInitialNotification;
    if (pending != null) {
      _pendingInitialNotification = null;
      if (!_shouldConsumeTap(pending)) return;
      _scheduleNavigation(() {
        unawaited(handleNotificationNavigation(pending));
      });
    }
  }

  static void _scheduleNavigation(VoidCallback action) {
    if (debugPushRouteOverride != null || debugModalOverride != null) {
      action();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      action();
    });
  }

  void _pushRoute(GoRouter? router, String route, {Object? extra}) {
    if (debugPushRouteOverride != null) {
      debugPushRouteOverride!(route, extra);
      return;
    }
    if (router == null) return;
    final currentPath = _currentRouterPath();
    if (currentPath.isEmpty || currentPath == '/splash') {
      router.go('/dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(route, extra: extra);
      });
      return;
    }
    router.push(route, extra: extra);
  }

  void _withMountedContext(
    GoRouter? router,
    void Function(BuildContext ctx) onMounted, {
    VoidCallback? onFallback,
    int remainingAttempts = 4,
  }) {
    final ctx = router?.routerDelegate.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      onMounted(ctx);
      return;
    }
    if (remainingAttempts > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _withMountedContext(
          router,
          onMounted,
          onFallback: onFallback,
          remainingAttempts: remainingAttempts - 1,
        );
      });
      return;
    }
    onFallback?.call();
  }

  Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting business FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('tu_lojita_business_device_id');
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = const Uuid().v4();
        await prefs.setString('tu_lojita_business_device_id', deviceId);
      }

      final platform = Platform.isIOS ? 'ios' : 'android';

      await _dio.post('/notifications/register-device', data: {
        'fcmToken': fcmToken,
        'platform': platform,
        'deviceId': deviceId,
      });

      debugPrint(
          'Business FCM device registered successfully with backend: $deviceId');
    } catch (e) {
      debugPrint('Failed to register Business FCM device with backend: $e');
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('tu_lojita_business_device_id');
      if (deviceId == null || deviceId.isEmpty) return;

      await _dio.post(
        '/notifications/unregister-device',
        data: {
          'deviceId': deviceId,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      debugPrint(
          'Business FCM device unregistered successfully from backend: $deviceId');
    } catch (e) {
      debugPrint('Failed to unregister Business FCM device from backend: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Siempre refrescar la bandeja interna al recibir un push en primer plano
    onNotificationReceived?.call();

    final notificationId =
        message.data['notificationId'] ?? message.messageId;

    if (!_deduplicator.shouldProcess(notificationId)) {
      debugPrint(
          'Business FCM foreground message $notificationId suppressed (already delivered by WebSocket)');
      return;
    }

    final rawOrderId = message.data['orderId']?.toString() ?? '';
    final rawTargetId = message.data['targetId']?.toString() ?? '';
    final storeId = message.data['storeId']?.toString() ?? '';
    final type = message.data['type']?.toString() ?? '';
    final channelType = (message.data['channelType'] ?? '').toString();

    final notifTitle = message.notification?.title?.trim();
    final dataTitle = message.data['title']?.toString().trim();
    final title = (notifTitle != null && notifTitle.isNotEmpty)
        ? notifTitle
        : ((dataTitle != null && dataTitle.isNotEmpty)
            ? dataTitle
            : _resolveDefaultTitle(type));

    final notifBody = message.notification?.body?.trim();
    final dataBody = message.data['body']?.toString().trim();
    final body = (notifBody != null && notifBody.isNotEmpty)
        ? notifBody
        : ((dataBody != null && dataBody.isNotEmpty)
            ? dataBody
            : _resolveDefaultBody(type));

    final bool isStoreMediation = (type == 'MEDIATION_REQUEST' ||
            type == 'MEDIATION_RESPONSE') &&
        ((storeId.isNotEmpty && rawTargetId == storeId) ||
            (channelType != 'DISPUTE_BUYER_SELLER' &&
                !title.toString().toLowerCase().contains('reclamo') &&
                !body.toString().toLowerCase().contains('reclamo') &&
                !body.toString().toLowerCase().contains('pedido') &&
                !body.toString().toLowerCase().contains('orden') &&
                rawOrderId.isEmpty));

    final isOrderRelated = !isStoreMediation &&
        (rawOrderId.isNotEmpty ||
            type == 'ORDER_CREATED' ||
            type == 'ORDER_STATUS_CHANGED' ||
            type == 'PAYMENT_REPORTED' ||
            type == 'PAYMENT_APPROVED' ||
            type == 'PAYMENT_REJECTED' ||
            type == 'REFUND_REPORTED' ||
            type == 'REFUND_CONFIRMED' ||
            type == 'CHAT_MESSAGE' ||
            type == 'SUPPORT_CHAT_MESSAGE' ||
            type == 'DISPUTE_ESCALATED' ||
            type == 'MEDIATION_REQUEST' ||
            type == 'MEDIATION_RESPONSE' ||
            type == 'BUYER_REVIEW_PROMPT' ||
            type == 'ORDER_REVIEW_RECEIVED' ||
            type.startsWith('ORDER_') ||
            type.startsWith('PAYMENT_') ||
            type.startsWith('REFUND_'));

    final resolvedOrderId = rawOrderId.isNotEmpty
        ? rawOrderId
        : (isOrderRelated ? rawTargetId : '');

    final enrichedData = <String, dynamic>{
      ...message.data,
      'title': title,
      'body': body,
      'orderId': resolvedOrderId,
    };

    onPayloadCallback?.call(enrichedData);

    if (resolvedOrderId.isNotEmpty && isOrderRelated) {
      onOrderNotificationCallback?.call(resolvedOrderId);
    }

    if (type == 'CHAT_MESSAGE' || type == 'SUPPORT_CHAT_MESSAGE') {
      final ch = channelType.toUpperCase();
      final isSupport = type == 'SUPPORT_CHAT_MESSAGE' ||
          ch.contains('SUPPORT') ||
          (ch.isEmpty &&
              (title.toString().toLowerCase().contains('soporte') ||
                  body.toString().toLowerCase().contains('soporte')));
      if (resolvedOrderId.isNotEmpty &&
          isViewingChatCallback != null &&
          isViewingChatCallback!(resolvedOrderId, isSupport: isSupport)) {
        if (notificationId != null && notificationId.toString().isNotEmpty) {
          onActiveChatNotificationCallback?.call(notificationId.toString());
        }
        return;
      }
    }

    NotificationHelper.showNotification(
      id: notificationId.hashCode,
      title: title.toString(),
      body: body.toString(),
      payload: jsonEncode(enrichedData),
    );
  }

  Future<void> handleNotificationNavigation(Map<String, dynamic> data) async {
    final notificationId = data['notificationId'] ?? data['id'];
    if (notificationId != null && notificationId.toString().isNotEmpty) {
      final idStr = notificationId.toString();
      NotificationHelper.cancelNotification(idStr.hashCode).catchError((_) {});
      try {
        if (onMarkAsRead != null) {
          onMarkAsRead!(idStr);
        } else {
          _dio.patch('/notifications/$idStr/read').ignore();
        }
      } catch (_) {}
    }

    final rawOrderId = data['orderId']?.toString() ?? '';
    final rawTargetId = data['targetId']?.toString() ?? '';
    final rawStoreId = data['storeId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final channelType = (data['channelType'] ?? '').toString();
    final title = (data['title'] ?? '').toString();
    final body = (data['body'] ?? '').toString();

    final bool isModeration = isModerationNotice(
      type: type,
      title: title,
      body: body,
    );

    final bool isStoreMediation =
        (type == 'MEDIATION_REQUEST' || type == 'MEDIATION_RESPONSE') &&
            ((rawStoreId.isNotEmpty && rawTargetId == rawStoreId) ||
                (channelType != 'DISPUTE_BUYER_SELLER' &&
                    !title.toLowerCase().contains('reclamo') &&
                    !body.toLowerCase().contains('reclamo') &&
                    !body.toLowerCase().contains('pedido') &&
                    !body.toLowerCase().contains('orden') &&
                    rawOrderId.isEmpty));

    final bool isStoreTargetedType = type == 'STRIKE_APPLIED' ||
        type == 'STORE_SUSPENDED' ||
        type == 'STORE_FLAGGED' ||
        type == 'DIVISION_UP' ||
        type == 'DIVISION_DOWN' ||
        type == 'WEEKLY_RANKING_SUMMARY' ||
        type == 'STREAK_EXPIRING' ||
        type == 'CATEGORY_RIVALRY' ||
        type == 'RANK_SHIELD_EXPIRING' ||
        type == 'DANGER_ZONE_ALERT' ||
        isStoreMediation;

    var resolvedStoreId = rawStoreId.isNotEmpty
        ? rawStoreId
        : (isStoreTargetedType && rawTargetId.isNotEmpty ? rawTargetId : '');

    if (resolvedStoreId.isEmpty) {
      var fallback = getFallbackStoreId?.call() ?? '';
      if (fallback.isEmpty && ensureStoresLoaded != null) {
        try {
          await ensureStoresLoaded!();
          fallback = getFallbackStoreId?.call() ?? '';
        } catch (_) {}
      }
      resolvedStoreId = fallback;
    }

    final bool isNonOrderType = isStoreMediation ||
        isStoreTargetedType ||
        isModeration ||
        type == 'PROMO' ||
        type == 'CUSTOMER_BLOCKED' ||
        type == 'CUSTOMER_UNBLOCKED' ||
        type == 'ITEM_HIDDEN' ||
        type == 'REPORT_RESOLUTION' ||
        type == 'CHAT_PENALTY' ||
        type == 'ACHIEVEMENT_UNLOCKED';

    final orderId = !isNonOrderType && rawOrderId.isNotEmpty
        ? rawOrderId
        : (!isNonOrderType ? rawTargetId : '');

    GoRouter? router;
    if (debugPushRouteOverride == null && debugModalOverride == null) {
      try {
        router = _getRouter();
      } catch (_) {}
    }
    final ctx = router?.routerDelegate.navigatorKey.currentContext;

    // Validar acceso a sucursal para colaboradores
    if (resolvedStoreId.isNotEmpty &&
        canAccessBranch != null &&
        !canAccessBranch!(resolvedStoreId)) {
      if (ctx != null && ctx.mounted) {
        NotificationService.showError(
          ctx,
          'No tienes acceso a la sucursal asociada a esta notificación.',
        );
      }
      _pushRoute(router, '/dashboard/notifications');
      return;
    }

    bool checkPerms(List<String> perms, String errorMsg) {
      if (hasPermission == null) return true;
      final allowed = perms.any((p) => hasPermission!(p));
      if (!allowed && ctx != null && ctx.mounted) {
        NotificationService.showError(ctx, errorMsg);
      }
      return allowed;
    }

    if (type == 'STRIKE_APPLIED' || type == 'STORE_SUSPENDED') {
      if (!checkPerms(
        ['settings:manage'],
        'No tienes los permisos requeridos para gestionar la salud de la sucursal.',
      )) {
        return;
      }
      if (resolvedStoreId.isEmpty) {
        _pushRoute(router, '/dashboard/notifications');
        return;
      }
      if (debugModalOverride != null) {
        debugModalOverride!('STORE_HEALTH', {
          'storeId': resolvedStoreId,
          'type': type,
        });
        return;
      }
      _withMountedContext(
        router,
        (mountedCtx) => StoreHealthSheet.show(mountedCtx, resolvedStoreId),
        onFallback: () => _pushRoute(router, '/dashboard/notifications'),
      );
    } else if (type == 'ITEM_HIDDEN') {
      if (!checkPerms(
        ['items:view', 'items:edit', 'items:create', 'items:adjust_stock'],
        'No tienes los permisos requeridos para acceder al catálogo de artículos.',
      )) {
        return;
      }
      if (resolvedStoreId.isNotEmpty) {
        _pushRoute(router, '/dashboard/stores/$resolvedStoreId/items');
      } else {
        _pushRoute(router, '/dashboard/notifications');
      }
    } else if (type == 'REPORT_RESOLUTION') {
      if (debugModalOverride != null) {
        debugModalOverride!(
          rawTargetId.isNotEmpty ? 'REPORT_DETAIL' : 'CHAT_PENALTY',
          {
            'targetId': rawTargetId,
            'title': title.isNotEmpty ? title : 'Moderación',
            'body': body,
          },
        );
        return;
      }
      _withMountedContext(
        router,
        (mountedCtx) {
          if (rawTargetId.isNotEmpty) {
            ReportDetailSheet.show(mountedCtx, rawTargetId);
          } else {
            ChatPenaltyExplanationModal.show(
              mountedCtx,
              title: title.isNotEmpty ? title : 'Moderación',
              body: body,
            );
          }
        },
        onFallback: () => _pushRoute(router, '/dashboard/notifications'),
      );
    } else if (isModeration) {
      final modalTitle = title.isNotEmpty ? title : 'Aviso de Moderación';
      if (debugModalOverride != null) {
        debugModalOverride!('CHAT_PENALTY', {
          'title': modalTitle,
          'body': body,
        });
        return;
      }
      _withMountedContext(
        router,
        (mountedCtx) => ChatPenaltyExplanationModal.show(
          mountedCtx,
          title: modalTitle,
          body: body,
        ),
        onFallback: () => _pushRoute(router, '/dashboard/notifications'),
      );
    } else if (type == 'ACHIEVEMENT_UNLOCKED') {
      if (!checkPerms(
        ['reports:view', 'settings:manage'],
        'No tienes los permisos requeridos para ver logros y ranking.',
      )) {
        return;
      }
      int bonus = int.tryParse(data['lpBonus']?.toString() ?? '') ?? 0;
      if (bonus == 0) {
        final match = RegExp(r'\+(\d+)\s*(?:LP|PR)', caseSensitive: false)
            .firstMatch(body);
        if (match != null) {
          bonus = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }
      String achievementTitle =
          (data['achievementTitle'] ?? data['title'] ?? title).toString();
      String achievementDesc = (data['description'] ?? body).toString();
      final titleMatch = RegExp(r'["“«](.+?)["”»]').firstMatch(body);
      if (titleMatch != null && titleMatch.group(1) != null) {
        achievementTitle = titleMatch.group(1)!;
      }
      String badgeUrl = resolveAchievementBadgeUrl(
        data['badgeUrl']?.toString(),
        achievementName: achievementTitle,
      );

      if (rawTargetId.isNotEmpty) {
        try {
          final res = await _dio
              .get('/ranking/achievements/$rawTargetId')
              .timeout(const Duration(seconds: 4));
          if (res.data is Map<String, dynamic>) {
            final achData = res.data as Map<String, dynamic>;
            if (achData['name'] != null &&
                achData['name'].toString().isNotEmpty) {
              achievementTitle = achData['name'].toString();
            }
            if (achData['description'] != null &&
                achData['description'].toString().isNotEmpty) {
              achievementDesc = achData['description'].toString();
            }
            if (achData['lpBonus'] != null) {
              bonus = int.tryParse(achData['lpBonus'].toString()) ?? bonus;
            }
            final rawImg =
                (achData['imageUrl'] ?? achData['badgeUrl'])?.toString();
            badgeUrl = resolveAchievementBadgeUrl(
              rawImg,
              achievementName: achievementTitle,
            );
          }
        } catch (_) {}
      }

      _pushRoute(
        router,
        '/dashboard/ranking/achievement-unlocked',
        extra: {
          ...data,
          'title': achievementTitle,
          'achievementTitle': achievementTitle,
          'description': achievementDesc,
          'lpBonus': bonus,
          'badgeUrl': badgeUrl,
          'storeId': resolvedStoreId,
        },
      );
    } else if (type == 'DIVISION_UP') {
      if (!checkPerms(
        ['reports:view', 'settings:manage'],
        'No tienes los permisos requeridos para ver logros y ranking.',
      )) {
        return;
      }
      final divMatch = RegExp(
        r'(GRAN MAESTRO|RETADOR|DIAMANTE|PLATINO|MAESTRO|BRONCE|PLATA|ORO|HIERRO)',
        caseSensitive: false,
      ).firstMatch(body);
      final division = data['division']?.toString() ??
          divMatch?.group(1)?.toUpperCase() ??
          'BRONCE';
      _pushRoute(
        router,
        '/dashboard/ranking/celebration',
        extra: {
          ...data,
          'division': division,
          'storeId': resolvedStoreId,
        },
      );
    } else if (type == 'DIVISION_DOWN') {
      if (!checkPerms(
        ['reports:view', 'settings:manage'],
        'No tienes los permisos requeridos para ver logros y ranking.',
      )) {
        return;
      }
      final divMatch = RegExp(
        r'(GRAN MAESTRO|RETADOR|DIAMANTE|PLATINO|MAESTRO|BRONCE|PLATA|ORO|HIERRO)',
        caseSensitive: false,
      ).firstMatch(body);
      final division = data['division']?.toString() ??
          divMatch?.group(1)?.toUpperCase() ??
          'HIERRO';
      _pushRoute(
        router,
        '/dashboard/ranking/division-down',
        extra: {
          ...data,
          'division': division,
          'storeId': resolvedStoreId,
        },
      );
    } else if (type == 'STORE_FLAGGED') {
      if (!checkPerms(
        ['settings:manage'],
        'No tienes los permisos requeridos para gestionar esta configuración.',
      )) {
        return;
      }
      _pushRoute(
        router,
        '/dashboard/ranking/flagged',
        extra: {
          ...data,
          'storeId': resolvedStoreId,
          'reason': data['reason'] ?? body,
        },
      );
    } else if (type == 'WEEKLY_RANKING_SUMMARY' ||
        type == 'STREAK_EXPIRING' ||
        type == 'CATEGORY_RIVALRY' ||
        type == 'RANK_SHIELD_EXPIRING' ||
        type == 'DANGER_ZONE_ALERT') {
      if (!checkPerms(
        ['reports:view', 'settings:manage'],
        'No tienes los permisos requeridos para ver logros y ranking.',
      )) {
        return;
      }
      if (resolvedStoreId.isNotEmpty) {
        _pushRoute(router, '/dashboard/stores/$resolvedStoreId/ranking');
      } else {
        _pushRoute(router, '/dashboard/notifications');
      }
    } else if (isStoreMediation ||
        (type == 'MEDIATION_REQUEST' && orderId.isEmpty)) {
      if (!checkPerms(
        ['disputes:view', 'disputes:respond'],
        'No tienes los permisos requeridos para gestionar reclamos o mediaciones.',
      )) {
        return;
      }
      if (resolvedStoreId.isNotEmpty) {
        _pushRoute(
          router,
          '/dashboard/stores/$resolvedStoreId/mediation-requests',
        );
      } else {
        _pushRoute(router, '/dashboard/notifications');
      }
    } else if (type == 'MEDIATION_REQUEST' ||
        type == 'MEDIATION_RESPONSE' ||
        type == 'DISPUTE_ESCALATED') {
      if (!checkPerms(
        ['disputes:view', 'disputes:respond'],
        'No tienes los permisos requeridos para gestionar reclamos o mediaciones.',
      )) {
        return;
      }
      if (orderId.isNotEmpty) {
        _pushRoute(router, '/dashboard/orders/$orderId?openDispute=true');
      } else if (resolvedStoreId.isNotEmpty) {
        _pushRoute(
          router,
          '/dashboard/stores/$resolvedStoreId/mediation-requests',
        );
      } else {
        _pushRoute(router, '/dashboard/notifications');
      }
    } else if (type == 'CHAT_MESSAGE' || type == 'SUPPORT_CHAT_MESSAGE') {
      final ch = channelType.toUpperCase();
      final isSupport = type == 'SUPPORT_CHAT_MESSAGE' ||
          ch.contains('SUPPORT') ||
          (ch.isEmpty &&
              (title.toLowerCase().contains('soporte') ||
                  body.toLowerCase().contains('soporte')));
      if (isSupport &&
          !checkPerms(
            ['disputes:view', 'disputes:respond'],
            'No tienes los permisos requeridos para acceder al chat de soporte.',
          )) {
        return;
      }
      if (!isSupport &&
          !checkPerms(
            ['orders:chat'],
            'No tienes los permisos requeridos para acceder al chat de pedidos.',
          )) {
        return;
      }
      if (orderId.isNotEmpty) {
        if (isSupport) {
          _pushRoute(router, '/dashboard/orders/$orderId/support-chat');
        } else {
          _pushRoute(router, '/dashboard/orders/$orderId/chat');
        }
      } else {
        _pushRoute(router, '/dashboard/notifications');
      }
    } else if (type == 'ORDER_CREATED' ||
        type == 'ORDER_STATUS_CHANGED' ||
        type == 'PAYMENT_REPORTED' ||
        type == 'PAYMENT_APPROVED' ||
        type == 'PAYMENT_REJECTED' ||
        type == 'REFUND_REPORTED' ||
        type == 'REFUND_CONFIRMED' ||
        type == 'BUYER_REVIEW_PROMPT' ||
        type == 'ORDER_REVIEW_RECEIVED' ||
        type.startsWith('REFUND_') ||
        (orderId.isNotEmpty &&
            (type.startsWith('ORDER_') ||
                type.startsWith('PAYMENT_') ||
                type == 'GENERAL'))) {
      if (!checkPerms(
        [
          'orders:view',
          'orders:process',
          'orders:cancel',
          'installments:view',
          'installments:approve_payment',
        ],
        'No tienes los permisos requeridos para consultar el detalle de pedidos.',
      )) {
        return;
      }
      if (orderId.isNotEmpty) {
        _pushRoute(router, '/dashboard/orders/$orderId');
      } else {
        _pushRoute(router, '/dashboard/notifications');
      }
    } else {
      _pushRoute(router, '/dashboard/notifications');
      if (title.isNotEmpty || body.isNotEmpty) {
        final infoTitle = title.isNotEmpty ? title : 'Notificación';
        if (debugModalOverride != null) {
          debugModalOverride!('GENERAL_INFO', {
            'title': infoTitle,
            'body': body,
          });
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _withMountedContext(router, (mountedCtx) {
            showDialog(
              context: mountedCtx,
              builder: (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.indigo,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        infoTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
      }
    }
  }
}
