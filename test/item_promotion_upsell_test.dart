import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_promotion_provider.dart';

void main() {
  group('ItemPromotionProvider & Upsell Logic Tests', () {
    test('PromotionConfig deserializa correctamente con valores por defecto', () {
      const configDefault = PromotionConfig();
      expect(configDefault.enabled, isTrue);
      expect(configDefault.title, equals('Artículos Destacados'));
      expect(configDefault.carouselSeconds, equals(5));
      expect(configDefault.maxItems, equals(10));
      expect(configDefault.fillWithBestSellers, isTrue);
      expect(configDefault.pricePerDay, equals(2.0));
    });

    test('PromotionConfig deserializa correctamente desde JSON personalizado', () {
      final json = {
        'enabled': true,
        'title': 'Vitrina Exclusiva',
        'carouselSeconds': 8,
        'maxItems': 5,
        'fillWithBestSellers': false,
        'pricePerDay': 3.5,
      };

      final config = PromotionConfig.fromJson(json);
      expect(config.enabled, isTrue);
      expect(config.title, equals('Vitrina Exclusiva'));
      expect(config.carouselSeconds, equals(8));
      expect(config.maxItems, equals(5));
      expect(config.fillWithBestSellers, isFalse);
      expect(config.pricePerDay, equals(3.5));
    });

    test('Cálculo de cotización de inversión por paquete de días', () {
      const pricePerDay = 2.50;

      double calculateInvestment(int days) => days * pricePerDay;

      expect(calculateInvestment(3), equals(7.50));
      expect(calculateInvestment(7), equals(17.50));
      expect(calculateInvestment(15), equals(37.50));
      expect(calculateInvestment(30), equals(75.00));
    });

    test('ItemPromotionInfo identifica correctamente promociones activas y pendientes', () {
      final json = {
        'hasActivePromotion': true,
        'activePromotion': {
          'id': 'promo-123',
          'status': 'approved',
          'days': 7,
          'startsAt': '2026-11-01T00:00:00.000Z',
          'expiresAt': '2026-11-08T00:00:00.000Z',
        },
        'pendingPromotion': null,
      };

      final info = ItemPromotionInfo.fromJson(json);
      expect(info.hasActivePromotion, isTrue);
      expect(info.activePromotion?['id'], equals('promo-123'));
      expect(info.pendingPromotion, isNull);
    });
  });
}

