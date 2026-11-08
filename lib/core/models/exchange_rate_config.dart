class ExchangeRateConfig {
  final bool enabled;
  final double rate;
  final String currency;
  final String symbol;
  final String source;
  final String mode;
  final DateTime? updatedAt;

  const ExchangeRateConfig({
    required this.enabled,
    required this.rate,
    this.currency = 'VES',
    this.symbol = 'Bs.',
    this.source = 'BCV',
    this.mode = 'AUTO',
    this.updatedAt,
  });

  factory ExchangeRateConfig.fromJson(Map<String, dynamic> json) {
    return ExchangeRateConfig(
      enabled: json['enabled'] == true,
      rate: (json['rate'] is num) ? (json['rate'] as num).toDouble() : 0.0,
      currency: json['currency'] as String? ?? 'VES',
      symbol: json['symbol'] as String? ?? 'Bs.',
      source: json['source'] as String? ?? 'BCV',
      mode: json['mode'] as String? ?? 'AUTO',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  factory ExchangeRateConfig.disabled() {
    return const ExchangeRateConfig(enabled: false, rate: 0.0);
  }

  double toBolivares(double amountInUsd) {
    if (!enabled || rate <= 0) return 0.0;
    return amountInUsd * rate;
  }
}

