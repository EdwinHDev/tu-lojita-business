import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class StoreMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final dynamic icon;
  final Color color;
  final String? subtitle;

  const StoreMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  Color get _resolvedBgColor {
    if (color == Colors.green) return const Color(0xFFECFDF5);
    if (color == Colors.blue) return const Color(0xFFEFF6FF);
    if (color == Colors.orange) return const Color(0xFFFFF7ED);
    return color.withValues(alpha: 0.1);
  }

  Color get _resolvedTextColor {
    if (color == Colors.green) return const Color(0xFF047857);
    if (color == Colors.blue) return const Color(0xFF1D4ED8);
    if (color == Colors.orange) return const Color(0xFFC2410C);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _resolvedBgColor,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: icon,
                  color: _resolvedTextColor,
                  size: 20,
                ),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _resolvedBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: _resolvedTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
