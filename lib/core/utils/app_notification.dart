import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

/// Legacy notification helper redirected to the platform-standard [NotificationService]
/// to guarantee high-fidelity, floating glassmorphic feedback and prevent visual regressions.
class AppNotification {
  static void showSuccess(BuildContext context, String message) {
    NotificationService.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    NotificationService.showError(context, message);
  }

  static void showWarning(BuildContext context, String message) {
    NotificationService.showWarning(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    NotificationService.showInfo(context, message);
  }
}
