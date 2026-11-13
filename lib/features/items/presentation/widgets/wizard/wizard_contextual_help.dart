import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';

/// Opens a unified contextual help bottom sheet with explanation, optional example, and bullet points.
void showWizardContextualHelpSheet(
  BuildContext context, {
  required String title,
  required String explanation,
  String? example,
  List<String>? bulletPoints,
  IconData icon = Icons.help_outline_rounded,
  Color color = TuLojitaBrandColors.primary,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
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
  );
}

/// Interactive '?' button that opens a contextual help modal sheet.
class WizardContextualHelpButton extends StatelessWidget {
  final String title;
  final String explanation;
  final String? example;
  final List<String>? bulletPoints;
  final IconData icon;
  final Color color;

  const WizardContextualHelpButton({
    super.key,
    required this.title,
    required this.explanation,
    this.example,
    this.bulletPoints,
    this.icon = Icons.help_outline_rounded,
    this.color = TuLojitaBrandColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showWizardContextualHelpSheet(
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline_rounded, size: 15, color: color),
              const SizedBox(width: 3),
              Text(
                'Guía',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized section header with optional trailing contextual help button.
class WizardSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? helpButton;
  final String? helpTitle;
  final String? helpExplanation;
  final String? helpExample;
  final IconData? helpIcon;

  const WizardSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.helpButton,
    this.helpTitle,
    this.helpExplanation,
    this.helpExample,
    this.helpIcon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHelpButton = helpButton ??
        ((helpTitle != null && helpExplanation != null)
            ? WizardContextualHelpButton(
                title: helpTitle!,
                explanation: helpExplanation!,
                example: helpExample,
                icon: helpIcon ?? Icons.help_outline_rounded,
              )
            : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (effectiveHelpButton != null) ...[
          const SizedBox(width: 8),
          effectiveHelpButton,
        ],
      ],
    );
  }
}

/// Reactive helper widget that renders the live Bolivares (`≈ Bs. X.XXX,XX`) equivalent
/// below any USD input field or inside cards when the BCV rate is active.
class WizardLiveBcvHelper extends ConsumerWidget {
  final double? amountInUsd;
  final String prefix;
  final String? suffix;
  final TextStyle? style;

  const WizardLiveBcvHelper({
    super.key,
    required this.amountInUsd,
    this.prefix = '≈ ',
    this.suffix,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = amountInUsd;
    if (amount == null || amount <= 0) {
      return const SizedBox.shrink();
    }

    final config = ref.watch(exchangeRateProvider).asData?.value;
    if (!PriceFormatter.isDualEnabled(config) || config == null) {
      return const SizedBox.shrink();
    }

    final bsAmount = config.toBolivares(amount);
    final bsFormatted = PriceFormatter.formatBsNumeric(
      bsAmount,
      symbol: config.symbol,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 2),
      child: Text(
        '$prefix$bsFormatted${suffix ?? ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style ??
            const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.inkSecondary,
            ),
      ),
    );
  }
}

/// Formats a USD amount with an inline Bolivares reference (`$ 10,00 · ~ Bs. 500,00`).
String formatWizardDualInline(
  ExchangeRateConfig? config,
  double amountUsd, {
  String usdPrefix = '\$',
}) {
  final usdStr = '$usdPrefix${amountUsd.toStringAsFixed(2)}';
  if (!PriceFormatter.isDualEnabled(config) || config == null) {
    return usdStr;
  }
  final bsFormatted = PriceFormatter.formatBsNumeric(
    config.toBolivares(amountUsd),
    symbol: config.symbol,
  );
  return '$usdStr · ~ $bsFormatted';
}
