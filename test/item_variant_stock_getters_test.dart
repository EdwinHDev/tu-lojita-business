import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';

void main() {
  group('Item stock and variant getters tests', () {
    test('non-variant item without inventory tracking is always in stock', () {
      const item = Item(
        id: 'item-1',
        title: 'Unlimited Item',
        description: 'Test',
        price: 10.0,
        mainImage: 'https://example.com/img.jpg',
        images: [],
        isFeatured: false,
        itemType: ItemType.product,
        trackInventory: false,
        stockQuantity: 0,
        requiresBooking: false,
        hasVariants: false,
      );

      expect(item.isInStock, isTrue);
      expect(item.isOutOfStock, isFalse);
      expect(item.totalStockQuantity, 0.0);
      expect(item.hasDifferentVariantPrices, isFalse);
      expect(item.variantPriceRange, (min: 10.0, max: 10.0));
    });

    test('non-variant item with inventory tracking evaluates stockQuantity', () {
      const inStockItem = Item(
        id: 'item-2',
        title: 'Tracked In Stock',
        description: 'Test',
        price: 25.0,
        mainImage: 'https://example.com/img.jpg',
        images: [],
        isFeatured: false,
        itemType: ItemType.product,
        trackInventory: true,
        stockQuantity: 15,
        requiresBooking: false,
        hasVariants: false,
      );

      expect(inStockItem.isInStock, isTrue);
      expect(inStockItem.isOutOfStock, isFalse);
      expect(inStockItem.totalStockQuantity, 15.0);

      const outOfStockItem = Item(
        id: 'item-3',
        title: 'Tracked Out Of Stock',
        description: 'Test',
        price: 25.0,
        mainImage: 'https://example.com/img.jpg',
        images: [],
        isFeatured: false,
        itemType: ItemType.product,
        trackInventory: true,
        stockQuantity: 0,
        requiresBooking: false,
        hasVariants: false,
      );

      expect(outOfStockItem.isInStock, isFalse);
      expect(outOfStockItem.isOutOfStock, isTrue);
      expect(outOfStockItem.totalStockQuantity, 0.0);
    });

    test('variant item calculates aggregate stock from active variants', () {
      const variantItem = Item(
        id: 'item-4',
        title: 'Shirt with Variants',
        description: 'Test',
        price: 20.0,
        mainImage: 'https://example.com/img.jpg',
        images: [],
        isFeatured: false,
        itemType: ItemType.product,
        trackInventory: true,
        stockQuantity: 0, // backend leaves 0 on parent
        requiresBooking: false,
        hasVariants: true,
        variants: [
          ItemVariant(
            id: 'v1',
            sku: 'SHIRT-RED-S',
            stockQuantity: 10,
            price: 20.0,
            isActive: true,
            axisValues: {'Color': 'Rojo', 'Talla': 'S'},
          ),
          ItemVariant(
            id: 'v2',
            sku: 'SHIRT-RED-M',
            stockQuantity: 5,
            price: 22.0,
            isActive: true,
            axisValues: {'Color': 'Rojo', 'Talla': 'M'},
          ),
          ItemVariant(
            id: 'v3',
            sku: 'SHIRT-BLUE-L',
            stockQuantity: 50, // Inactive variant should be ignored
            price: 30.0,
            isActive: false,
            axisValues: {'Color': 'Azul', 'Talla': 'L'},
          ),
        ],
      );

      // Total stock is 10 + 5 = 15 (v3 ignored because inactive)
      expect(variantItem.totalStockQuantity, 15.0);
      expect(variantItem.isInStock, isTrue);
      expect(variantItem.isOutOfStock, isFalse);
      expect(variantItem.hasDifferentVariantPrices, isTrue);
      expect(variantItem.variantPriceRange, (min: 20.0, max: 22.0));
    });

    test('variant item is out of stock only when all active variants have zero stock', () {
      const depletedVariantItem = Item(
        id: 'item-5',
        title: 'Depleted Shirt',
        description: 'Test',
        price: 20.0,
        mainImage: 'https://example.com/img.jpg',
        images: [],
        isFeatured: false,
        itemType: ItemType.product,
        trackInventory: true,
        stockQuantity: 0,
        requiresBooking: false,
        hasVariants: true,
        variants: [
          ItemVariant(
            id: 'v1',
            stockQuantity: 0,
            price: 20.0,
            isActive: true,
            axisValues: {'Talla': 'S'},
          ),
          ItemVariant(
            id: 'v2',
            stockQuantity: 0,
            price: 20.0,
            isActive: true,
            axisValues: {'Talla': 'M'},
          ),
        ],
      );

      expect(depletedVariantItem.totalStockQuantity, 0.0);
      expect(depletedVariantItem.isInStock, isFalse);
      expect(depletedVariantItem.isOutOfStock, isTrue);
      expect(depletedVariantItem.hasDifferentVariantPrices, isFalse);
      expect(depletedVariantItem.variantPriceRange, (min: 20.0, max: 20.0));
    });
  });
}
