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

  Future<ExchangeRateConfig> _fetchExchangeRate() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/platform-settings/public');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final exchangeJson = data['exchangeRate'] as Map<String, dynamic>?;
        if (exchangeJson != null) {
          return ExchangeRateConfig.fromJson(exchangeJson);
        }
      }
      return ExchangeRateConfig.disabled();
    } catch (_) {
      return ExchangeRateConfig.disabled();
    }
  }

  Future<void> refreshRate() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchExchangeRate());
  }
}

