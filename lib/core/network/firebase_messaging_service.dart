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
  await Firebase.initializeApp();
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

  static Map<String, dynamic>? _pendingInitialNotification;
  static bool _isAppReadyForDeepLinks = false;

  FirebaseMessagingService(
    this._dio,
    this._getRouter, {
    this.onMarkAsRead,
    this.onNotificationReceived,
    this.hasPermission,
    this.canAccessBranch,
    this.getFallbackStoreId,
    this.ensureStoresLoaded,
  });

  Future<void> init() async {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
          'Business FCM Permission status: ${settings.authorizationStatus}');

      await registerDeviceToken();

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

      // Foreground message listener con deduplicación estricta
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Segundo plano (Warm start)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        queueOrNavigate(message.data);
      });

      // App cerrada (Cold start - local notification)
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

      // App cerrada (Cold start - FCM)
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        queueOrNavigate(initialMessage.data);
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging in Business app: $e');
    }
  }

  void queueOrNavigate(Map<String, dynamic> data) {
    bool isOnSplash = false;
    try {
      final loc = _getRouter().routerDelegate.currentConfiguration.uri.path;
      isOnSplash = loc == '/splash' || loc.isEmpty;
    } catch (_) {}

    if (!_isAppReadyForDeepLinks || isOnSplash) {
      _pendingInitialNotification = Map<String, dynamic>.from(data);
      return;
    }
    handleNotificationNavigation(data);
  }

  void markAppReadyAndConsumePendingNotification() {
    _isAppReadyForDeepLinks = true;

    if (NotificationHelper.pendingLaunchPayload != null &&
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationNavigation(pending);
      });
    }
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

    final title = message.notification?.title ??
        message.data['title'] ??
        'Tu Lojita Comercio';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final rawOrderId = message.data['orderId']?.toString() ?? '';
    final rawTargetId = message.data['targetId']?.toString() ?? '';
    final storeId = message.data['storeId']?.toString() ?? '';
    final type = message.data['type']?.toString() ?? '';
    final channelType = (message.data['channelType'] ?? '').toString();

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
      NotificationHelper.cancelNotification(idStr.hashCode);
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
        type == 'CUSTOMER_BLOCKED' ||
        type == 'CUSTOMER_UNBLOCKED' ||
        type == 'ITEM_HIDDEN' ||
        type == 'REPORT_RESOLUTION' ||
        type == 'CHAT_PENALTY' ||
        type == 'ACHIEVEMENT_UNLOCKED';

    final orderId = !isNonOrderType && rawOrderId.isNotEmpty
        ? rawOrderId
        : (!isNonOrderType ? rawTargetId : '');

    final router = _getRouter();
    final ctx = router.routerDelegate.navigatorKey.currentContext;

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
      router.push('/dashboard/notifications');
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
      if (ctx != null && ctx.mounted && resolvedStoreId.isNotEmpty) {
        StoreHealthSheet.show(ctx, resolvedStoreId);
      } else {
        router.push('/dashboard/notifications');
      }
    } else if (type == 'ITEM_HIDDEN') {
      if (!checkPerms(
        ['items:view', 'items:edit', 'items:create', 'items:adjust_stock'],
        'No tienes los permisos requeridos para acceder al catálogo de artículos.',
      )) {
        return;
      }
      if (resolvedStoreId.isNotEmpty) {
        router.push('/dashboard/stores/$resolvedStoreId/items');
      } else {
        router.push('/dashboard/notifications');
      }
    } else if (type == 'REPORT_RESOLUTION') {
      if (ctx != null && ctx.mounted) {
        if (rawTargetId.isNotEmpty) {
          ReportDetailSheet.show(ctx, rawTargetId);
        } else {
          ChatPenaltyExplanationModal.show(
            ctx,
            title: title.isNotEmpty ? title : 'Moderación',
            body: body,
          );
        }
      } else {
        router.push('/dashboard/notifications');
      }
    } else if (type == 'CHAT_PENALTY' ||
        (type == 'GENERAL' &&
            (title.toLowerCase().contains('moderación') ||
                title.toLowerCase().contains('suspensión') ||
                title.toLowerCase().contains('advertencia')))) {
      if (ctx != null && ctx.mounted) {
        ChatPenaltyExplanationModal.show(
          ctx,
          title: title.isNotEmpty ? title : 'Aviso de Moderación',
          body: body,
        );
      } else {
        router.push('/dashboard/notifications');
      }
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
      String achievementDesc =
          (data['description'] ?? body).toString();
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

      router.push('/dashboard/ranking/achievement-unlocked', extra: {
        ...data,
        'title': achievementTitle,
        'achievementTitle': achievementTitle,
        'description': achievementDesc,
        'lpBonus': bonus,
        'badgeUrl': badgeUrl,
        'storeId': resolvedStoreId,
      });
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
      router.push('/dashboard/ranking/celebration', extra: {
        ...data,
        'division': division,
        'storeId': resolvedStoreId,
      });
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
      router.push('/dashboard/ranking/division-down', extra: {
        ...data,
        'division': division,
        'storeId': resolvedStoreId,
      });
    } else if (type == 'STORE_FLAGGED') {
      if (!checkPerms(
        ['settings:manage'],
        'No tienes los permisos requeridos para gestionar esta configuración.',
      )) {
        return;
      }
      router.push('/dashboard/ranking/flagged', extra: {
        ...data,
        'storeId': resolvedStoreId,
        'reason': data['reason'] ?? body,
      });
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
        router.push('/dashboard/stores/$resolvedStoreId/ranking');
      } else {
        router.push('/dashboard/notifications');
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
        router.push('/dashboard/stores/$resolvedStoreId/mediation-requests');
      } else {
        router.push('/dashboard/notifications');
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
        router.push('/dashboard/orders/$orderId?openDispute=true');
      } else if (resolvedStoreId.isNotEmpty) {
        router.push('/dashboard/stores/$resolvedStoreId/mediation-requests');
      } else {
        router.push('/dashboard/notifications');
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
          router.push('/orders/$orderId/support-chat');
        } else {
          router.push('/dashboard/orders/$orderId/chat');
        }
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
        router.push('/dashboard/orders/$orderId');
      } else {
        router.push('/dashboard/notifications');
      }
    } else {
      router.push('/dashboard/notifications');
    }
  }
}
