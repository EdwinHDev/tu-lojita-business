import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';

void main() {
  group('ItemFormState - Gobernanza y Reglas Semánticas de PriceType', () {
    test('isPriceTypeEnabled siempre permite FIXED y respeta lista habilitada', () {
      const state = ItemFormState(
        enabledPriceTypes: [PriceType.negotiable],
      );

      expect(state.isPriceTypeEnabled(PriceType.fixed), isTrue);
      expect(state.isPriceTypeEnabled(PriceType.negotiable), isTrue);
      expect(state.isPriceTypeEnabled(PriceType.startingAt), isFalse);
      expect(state.isPriceTypeEnabled(PriceType.onDemand), isFalse);
      expect(state.isPriceTypeEnabled(PriceType.free), isFalse);
    });

    test('validatePriceTypeRules rechaza guardar o republicar un tipo de precio deshabilitado', () {
      const state = ItemFormState(
        priceType: PriceType.negotiable,
        price: 15,
        enabledPriceTypes: [PriceType.fixed],
      );

      final error = state.validatePriceTypeRules();
      expect(error, isNotNull);
      expect(error, contains('deshabilitado'));
    });

    test('validatePriceTypeRules exige variantes distintas, extras pagos o servicio/reserva para STARTING_AT', () {
      const invalidSimpleProduct = ItemFormState(
        itemType: ItemType.product,
        priceType: PriceType.startingAt,
        price: 10,
      );
      expect(invalidSimpleProduct.validatePriceTypeRules(), isNotNull);

      const validWithPaidExtra = ItemFormState(
        itemType: ItemType.product,
        priceType: PriceType.startingAt,
        price: 10,
        customizationGroups: [
          CustomizationGroup(
            id: 'g1',
            name: 'Adicionales',
            minSelect: 0,
            maxSelect: 1,
            options: [
              CustomizationOption(id: 'o1', name: 'Empaque', price: 2.5),
            ],
          ),
        ],
      );
      expect(validWithPaidExtra.validatePriceTypeRules(), isNull);

      const validService = ItemFormState(
        itemType: ItemType.service,
        priceType: PriceType.startingAt,
        price: 25,
      );
      expect(validService.validatePriceTypeRules(), isNull);
    });

    test('validatePriceTypeRules rechaza FREE con personalizaciones o variantes con costo', () {
      const invalidFreeWithExtra = ItemFormState(
        itemType: ItemType.product,
        priceType: PriceType.free,
        price: 0,
        customizationGroups: [
          CustomizationGroup(
            id: 'g1',
            name: 'Adicionales',
            minSelect: 0,
            maxSelect: 1,
            options: [
              CustomizationOption(id: 'o1', name: 'Gift wrap', price: 1.0),
            ],
          ),
        ],
      );
      expect(invalidFreeWithExtra.validatePriceTypeRules(), isNotNull);

      const validFree = ItemFormState(
        itemType: ItemType.product,
        priceType: PriceType.free,
        price: 0,
      );
      expect(validFree.validatePriceTypeRules(), isNull);
    });
  });
}
