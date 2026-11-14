import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';

/// Opens a unified contextual help bottom sheet with explanation, optional
/// bullet points, and a highlighted practical example.
void showContextualHelpSheet(
  BuildContext context, {
  required String title,
  required String explanation,
  String? example,
  List<String>? bulletPoints,
  IconData icon = Icons.help_outline_rounded,
  Color color = TuLojitaBrandColors.primary,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.borderMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: TuLojitaBrandColors.inkSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                explanation,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
              if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...bulletPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (example != null && example.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TuLojitaBrandColors.borderMuted),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          example,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
  );
}

/// Interactive '?' pill button that opens [showContextualHelpSheet].
class ContextualHelpButton extends StatelessWidget {
  final String title;
  final String explanation;
  final String? example;
  final List<String>? bulletPoints;
  final IconData icon;
  final Color color;
  final String label;
  final bool compact;

  const ContextualHelpButton({
    super.key,
    required this.title,
    required this.explanation,
    this.example,
    this.bulletPoints,
    this.icon = Icons.help_outline_rounded,
    this.color = TuLojitaBrandColors.primary,
    this.label = 'Guía',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showContextualHelpSheet(
        context,
        title: title,
        explanation: explanation,
        example: example,
        bulletPoints: bulletPoints,
        icon: icon,
        color: color,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: 'Ver guía: $title',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 7,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: compact ? 13.5 : 15,
                color: color,
              ),
              if (label.isNotEmpty) ...[
                SizedBox(width: compact ? 2.5 : 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
