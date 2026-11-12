import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';

/// Widget unificado para renderizar precios en USD con referencia secundaria en Bolívares (BCV) en la app Business.
class DualPriceText extends ConsumerWidget {
  final double amountInUsd;
  final TextStyle? usdStyle;
  final TextStyle? bsStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isInline;
  final bool useScaleDown;
  final int maxLines;
  final String? prefix;
  final String? suffix;

  const DualPriceText({
    super.key,
    required this.amountInUsd,
    this.usdStyle,
    this.bsStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.isInline = false,
    this.useScaleDown = true,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRateAsync = ref.watch(exchangeRateProvider);
    final config = exchangeRateAsync.asData?.value;

    final formattedUsd = PriceFormatter.formatNumeric(amountInUsd);
    final usdText = '${prefix ?? ''}$formattedUsd${suffix ?? ''}';

    final defaultUsdStyle = usdStyle ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF111827),
        );

    final showBs = PriceFormatter.isDualEnabled(config);

    if (!showBs || config == null) {
      final singleText = Text(
        usdText,
        style: defaultUsdStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
      return useScaleDown
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: _getAlignment(crossAxisAlignment),
              child: singleText,
            )
          : singleText;
    }

    final activeConfig = config;
    final bsAmount = activeConfig.toBolivares(amountInUsd);
    final bsFormatted = PriceFormatter.formatBsNumeric(
      bsAmount,
      symbol: activeConfig.symbol,
    );
    final bsText = '~ $bsFormatted';

    final defaultBsStyle = bsStyle ??
        TextStyle(
          fontSize: (defaultUsdStyle.fontSize ?? 16) * 0.72,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6B7280),
        );

    if (isInline) {
      final inlineWidget = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          Text(usdText, style: defaultUsdStyle),
          Text(bsText, style: defaultBsStyle),
        ],
      );

      return useScaleDown
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: _getAlignment(crossAxisAlignment),
              child: inlineWidget,
            )
          : inlineWidget;
    }

    final columnWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          usdText,
          style: defaultUsdStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          bsText,
          style: defaultBsStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return useScaleDown
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: _getAlignment(crossAxisAlignment),
            child: columnWidget,
          )
        : columnWidget;
  }

  Alignment _getAlignment(CrossAxisAlignment align) {
    switch (align) {
      case CrossAxisAlignment.start:
        return Alignment.centerLeft;
      case CrossAxisAlignment.end:
        return Alignment.centerRight;
      case CrossAxisAlignment.center:
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }
}

