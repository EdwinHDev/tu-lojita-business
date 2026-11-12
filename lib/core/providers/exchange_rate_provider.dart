import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';

final exchangeRateProvider =
    AsyncNotifierProvider<ExchangeRateNotifier, ExchangeRateConfig>(() {
  return ExchangeRateNotifier();
});

class ExchangeRateNotifier extends AsyncNotifier<ExchangeRateConfig> {
  @override
  Future<ExchangeRateConfig> build() async {
    return _fetchExchangeRate();
  }

  Future<ExchangeRateConfig> _fetchExchangeRate({
    ExchangeRateConfig? previousConfig,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/platform-settings/public');
      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final exchangeRaw = data['exchangeRate'];
        if (exchangeRaw is Map) {
          return ExchangeRateConfig.fromJson(
            Map<String, dynamic>.from(exchangeRaw),
          );
        }
        return ExchangeRateConfig.disabled();
      }
      return previousConfig ?? ExchangeRateConfig.disabled();
    } catch (_) {
      return previousConfig ?? ExchangeRateConfig.disabled();
    }
  }

  /// Refreshes the active exchange rate without clearing any valid cached rate
  /// while fetching or if a transient network error occurs.
  Future<void> refreshRate() async {
    final previousConfig = state.asData?.value;
    if (previousConfig == null) {
      state = const AsyncValue.loading();
    }
    final nextConfig = await _fetchExchangeRate(previousConfig: previousConfig);
    if (!ref.mounted) return;
    state = AsyncValue.data(nextConfig);
  }
}
