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
  final NotificationDeduplicator _deduplicator = NotificationDeduplicator();

  FirebaseMessagingService(this._dio, this._getRouter, {this.onMarkAsRead});

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

  void _handleForegroundMessage(RemoteMessage message) {
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

    final orderId = data['orderId']?.toString() ?? '';
    final storeId = data['storeId']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final router = _getRouter();

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
  }
}
