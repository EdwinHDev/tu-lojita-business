import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';

/// Shared progress-bar metric tile used by branch performance and payment method tabs.
class HomeShareProgressTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final double amountInUsd;
  final double percentage;
  final String summaryLabel;
  final String? badgeText;

  const HomeShareProgressTile({
    super.key,
    required this.icon,
    required this.title,
    required this.amountInUsd,
    required this.percentage,
    required this.summaryLabel,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: TuLojitaBrandColors.indigo600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                  ),
                  if (badgeText != null && badgeText!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.amber100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.amber800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 135),
              child: DualPriceText(
                amountInUsd: amountInUsd,
                crossAxisAlignment: CrossAxisAlignment.end,
                usdStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: TuLojitaBrandColors.indigo600,
                ),
                bsStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: TuLojitaBrandColors.indigo50,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TuLojitaBrandColors.indigo600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 2,
              child: Text(
                summaryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  color: TuLojitaBrandColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
