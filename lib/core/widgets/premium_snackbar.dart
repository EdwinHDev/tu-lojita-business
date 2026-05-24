import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum SnackBarType { success, error, warning, info }

class PremiumSnackBarContent extends StatelessWidget {
  final String message;
  final SnackBarType type;

  const PremiumSnackBarContent({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color baseColor;
    dynamic icon;
    String title;

    switch (type) {
      case SnackBarType.success:
        baseColor = const Color(0xFF10B981);
        icon = HugeIcons.strokeRoundedTick01;
        title = '¡Éxito!';
        break;
      case SnackBarType.error:
        baseColor = const Color(0xFFEF4444);
        icon = HugeIcons.strokeRoundedAlert01;
        title = 'Error';
        break;
      case SnackBarType.warning:
        baseColor = const Color(0xFFF59E0B);
        icon = HugeIcons.strokeRoundedAlert02;
        title = 'Atención';
        break;
      case SnackBarType.info:
        baseColor = const Color(0xFF3B82F6);
        icon = HugeIcons.strokeRoundedInformationCircle;

        title = 'Información';
        break;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? baseColor.withValues(alpha: 0.15)
            : baseColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: baseColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: HugeIcon(icon: icon, color: baseColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: baseColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
