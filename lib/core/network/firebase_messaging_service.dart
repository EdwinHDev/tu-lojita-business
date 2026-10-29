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
  final NotificationDeduplicator _deduplicator = NotificationDeduplicator();
  static void Function(String orderId)? onOrderNotificationCallback;
  static void Function(Map<String, dynamic> data)? onPayloadCallback;

  FirebaseMessagingService(
    this._dio,
    this._getRouter, {
    this.onMarkAsRead,
    this.onNotificationReceived,
    this.hasPermission,
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
        handleNotificationNavigation(message.data);
      });

      // App cerrada (Cold start)
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging in Business app: $e');
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

      await _dio.post('/notifications/unregister-device', data: {
        'deviceId': deviceId,
      });
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

    final rawOrderId = message.data['orderId']?.toString() ??
        message.data['targetId']?.toString() ??
        '';
    final type = message.data['type']?.toString() ?? '';
    final isOrderRelated = !type.startsWith('DIVISION') &&
        !type.startsWith('ACHIEVEMENT') &&
        !type.startsWith('STORE_FLAGGED') &&
        !type.startsWith('WEEKLY_RANKING');
    onPayloadCallback?.call(Map<String, dynamic>.from(message.data));

    if (rawOrderId.isNotEmpty && isOrderRelated) {
      onOrderNotificationCallback?.call(rawOrderId);
    }

    NotificationHelper.showNotification(
      id: notificationId.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  void handleNotificationNavigation(Map<String, dynamic> data) {
    final notificationId = data['notificationId'] ?? data['id'];
    if (notificationId != null && notificationId.toString().isNotEmpty) {
      try {
        if (onMarkAsRead != null) {
          onMarkAsRead!(notificationId.toString());
        }
        _dio
            .patch('/notifications/${notificationId.toString()}/read')
            .ignore();
      } catch (_) {}
    }

    final rawOrderId = data['orderId']?.toString() ?? '';
    final rawTargetId = data['targetId']?.toString() ?? '';
    final storeId = data['storeId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final channelType = (data['channelType'] ?? '').toString();
    final title = (data['title'] ?? '').toString();
    final orderId = rawOrderId.isNotEmpty
        ? rawOrderId
        : (type != 'CUSTOMER_BLOCKED' && type != 'CUSTOMER_UNBLOCKED' ? rawTargetId : '');
    final router = _getRouter();
    bool canAccess(List<String> perms) {
      if (hasPermission == null) return true;
      return perms.any((p) => hasPermission!(p));
    }

    if (type == 'DIVISION_UP') {
      if (!canAccess(['reports:view', 'settings:manage'])) return;
      router.push('/dashboard/ranking/celebration', extra: data);
    } else if (type == 'DIVISION_DOWN') {
      if (!canAccess(['reports:view', 'settings:manage'])) return;
      router.push('/dashboard/ranking/division-down', extra: data);
    } else if (type == 'ACHIEVEMENT_UNLOCKED') {
      if (!canAccess(['reports:view', 'settings:manage'])) return;
      router.push('/dashboard/ranking/achievement-unlocked', extra: data);
    } else if (type == 'STORE_FLAGGED') {
      if (!canAccess(['settings:manage'])) return;
      router.push('/dashboard/ranking/flagged', extra: data);
    } else if (type == 'WEEKLY_RANKING_SUMMARY') {
      if (!canAccess(['reports:view', 'settings:manage'])) return;
      if (storeId.isNotEmpty) {
        router.push('/dashboard/stores/$storeId/ranking');
      } else {
        router.push('/dashboard/notifications');
      }
    } else if (type == 'MEDIATION_REQUEST' ||
        type == 'MEDIATION_RESPONSE' ||
        type == 'DISPUTE_ESCALATED') {
      if (!canAccess(['disputes:view', 'disputes:respond'])) return;
      if (orderId.isNotEmpty) {
        router.push('/dashboard/orders/$orderId?openDispute=true');
      } else if (storeId.isNotEmpty) {
        router.push('/dashboard/stores/$storeId/mediation-requests');
      } else {
        router.push('/dashboard/notifications');
      }
    } else if (type == 'CHAT_MESSAGE' || type == 'SUPPORT_CHAT_MESSAGE') {
      final isSupport = type == 'SUPPORT_CHAT_MESSAGE' ||
          channelType.isNotEmpty && channelType != 'DIRECT' ||
          title.toLowerCase().contains('soporte');
      if (isSupport && !canAccess(['disputes:view', 'disputes:respond'])) {
        return;
      }
      if (!isSupport && !canAccess(['orders:chat'])) {
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
    } else if (type == 'REPORT_RESOLUTION' || type == 'CHAT_PENALTY') {
      router.push('/dashboard/notifications');
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
      if (!canAccess([
        'orders:view',
        'orders:process',
        'orders:cancel',
        'installments:view',
        'installments:approve_payment',
      ])) {
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
