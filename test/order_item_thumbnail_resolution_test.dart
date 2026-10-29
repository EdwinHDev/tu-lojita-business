import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_item.dart';

void main() {
  group('OrderItem resolvedThumbnail Resolution Tests', () {
    test('resolves black dress variant thumbnail from axisValues pipe in order payload (order #FE2A54DA reproduction)', () {
      final json = {
        'id': 'oi-1',
        'title': 'Vestido Sasha',
        'price': '35.00',
        'quantity': 1,
        'variantId': '407f2de8-6300-40c5-95ae-2c6a9590d564',
        'variantLabel': 'Negro',
        'item': {
          'id': 'item-1',
          'title': 'Vestido Sasha',
          'mainImage': '/img/facccd52-e348-4c44-b7ee-111f73e123d8', // Brown dress (base product)
          'images': ['/img/facccd52-e348-4c44-b7ee-111f73e123d8'],
        },
        'variant': {
          'id': '407f2de8-6300-40c5-95ae-2c6a9590d564',
          'imageUrl': null,
          'axisValues': {
            'Color': 'Negro|#000000|/img/63dfb3a1-54f2-47d3-8811-09349846cc0e', // Black dress image!
          },
        },
      };

      final orderItem = OrderItem.fromJson(json);

      expect(orderItem.variant, isNotNull);
      expect(orderItem.resolvedThumbnail, equals('/img/63dfb3a1-54f2-47d3-8811-09349846cc0e'));
    });

    test('resolves variant thumbnail when variant has explicit imageUrl', () {
      final json = {
        'id': 'oi-2',
        'title': 'Camisa Casual',
        'price': '20.00',
        'quantity': 1,
        'variantId': 'var-2',
        'variantLabel': 'Azul',
        'item': {
          'id': 'item-2',
          'title': 'Camisa Casual',
          'mainImage': '/img/base-shirt.jpg',
        },
        'variant': {
          'id': 'var-2',
          'imageUrl': '/img/blue-shirt-variant.jpg',
          'axisValues': {'Color': 'Azul'},
        },
      };

      final orderItem = OrderItem.fromJson(json);

      expect(orderItem.resolvedThumbnail, equals('/img/blue-shirt-variant.jpg'));
    });

    test('resolves variant thumbnail from item.variants fallback if variant object is absent', () {
      final json = {
        'id': 'oi-3',
        'title': 'Zapato Deportivo',
        'price': '50.00',
        'quantity': 1,
        'variantId': 'var-3',
        'variantLabel': 'Rojo',
        'item': {
          'id': 'item-3',
          'title': 'Zapato Deportivo',
          'mainImage': '/img/base-shoe.jpg',
          'variants': [
            {
              'id': 'var-3',
              'axisValues': {'Color': 'Rojo|#FF0000|/img/red-shoe.jpg'},
            }
          ]
        },
      };

      final orderItem = OrderItem.fromJson(json);

      expect(orderItem.resolvedThumbnail, equals('/img/red-shoe.jpg'));
    });

    test('falls back to item.mainImage when item has no variants', () {
      final json = {
        'id': 'oi-4',
        'title': 'Accesorio Standard',
        'price': '10.00',
        'quantity': 1,
        'item': {
          'id': 'item-4',
          'title': 'Accesorio Standard',
          'mainImage': '/img/accessory-main.jpg',
        },
      };

      final orderItem = OrderItem.fromJson(json);

      expect(orderItem.resolvedThumbnail, equals('/img/accessory-main.jpg'));
    });
  });
}
