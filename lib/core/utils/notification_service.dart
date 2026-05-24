import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/widgets/premium_snackbar.dart';

class NotificationService {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.success);
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.error);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, SnackBarType.info);
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    SnackBarType type,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: PremiumSnackBarContent(message: message, type: type),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
