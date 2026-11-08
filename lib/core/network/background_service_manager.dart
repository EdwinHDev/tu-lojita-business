import 'package:flutter/foundation.dart';

/// Legacy background service placeholder for Tu Lojita Business.
/// Push notifications are handled directly by Firebase Cloud Messaging (FCM).
Future<void> stopBackgroundServiceIfRunning() async {
  debugPrint('BackgroundService: FCM is the active messaging handler.');
}
