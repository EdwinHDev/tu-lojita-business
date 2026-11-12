import 'package:intl/intl.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';

/// Pure currency formatting utilities standardized on `es_ES` grouping/decimals.
class PriceFormatter {
  static final NumberFormat _esFormatter = NumberFormat('#,##0.00', 'es_ES');

  static String formatNumeric(double amount) {
    return '\$ ${_esFormatter.format(amount)}';
  }

  static String formatBsNumeric(double amountInBs, {String symbol = 'Bs.'}) {
    final normalizedSymbol = symbol.trim().isEmpty ? 'Bs.' : symbol.trim();
    return '$normalizedSymbol ${_esFormatter.format(amountInBs)}';
  }

  /// Formats an exchange rate value (e.g., `Bs. 50,00`).
  static String formatRateValue(double rate, {String symbol = 'Bs.'}) {
    return formatBsNumeric(rate, symbol: symbol);
  }

  /// Returns `true` when [config] has dual currency reference enabled with a positive rate.
  static bool isDualEnabled(ExchangeRateConfig? config) {
    return config != null && config.enabled && config.rate > 0;
  }

  /// Formats [amountInUsd] with optional inline Bolívares reference:
  /// `$ 250,00 (~ Bs. 12.500,00)` when active, or `$ 250,00` when disabled.
  static String formatDualInline(
    double amountInUsd,
    ExchangeRateConfig? config, {
    String? prefix,
    String? suffix,
  }) {
    final usdText = '${prefix ?? ''}${formatNumeric(amountInUsd)}${suffix ?? ''}';
    if (!isDualEnabled(config)) return usdText;
    final bsFormatted = formatBsNumeric(
      config!.toBolivares(amountInUsd),
      symbol: config.symbol,
    );
    return '$usdText (~ $bsFormatted)';
  }

  /// Returns formatted lines: `[usdText, '~ Bs. ...']` when active,
  /// or `[usdText]` when disabled.
  static List<String> formatDualLines(
    double amountInUsd,
    ExchangeRateConfig? config, {
    String? prefix,
    String? suffix,
  }) {
    final usdText = '${prefix ?? ''}${formatNumeric(amountInUsd)}${suffix ?? ''}';
    if (!isDualEnabled(config)) return [usdText];
    final bsFormatted = formatBsNumeric(
      config!.toBolivares(amountInUsd),
      symbol: config.symbol,
    );
    return [usdText, '~ $bsFormatted'];
  }
}
