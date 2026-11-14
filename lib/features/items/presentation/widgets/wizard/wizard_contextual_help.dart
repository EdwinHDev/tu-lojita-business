import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/core/widgets/contextual_help_sheet.dart';

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
  showContextualHelpSheet(
    context,
    title: title,
    explanation: explanation,
    example: example,
    bulletPoints: bulletPoints,
    icon: icon,
    color: color,
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
    return ContextualHelpButton(
      title: title,
      explanation: explanation,
      example: example,
      bulletPoints: bulletPoints,
      icon: icon,
      color: color,
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
