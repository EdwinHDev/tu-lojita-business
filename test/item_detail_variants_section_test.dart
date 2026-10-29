import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_detail_screen.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  testWidgets(
      'ItemDetailScreen displays variants section, axes, variant cards and aggregate stock',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const variantItem = Item(
      id: 'item-variant-1',
      title: 'Camisa Polo Premium',
      description: 'Camisa polo de algodón pima peruano.',
      price: 20.0,
      mainImage: 'https://images.tulojita.com/polo.jpg',
      images: ['https://images.tulojita.com/polo.jpg'],
      isFeatured: true,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 0, // parent stock 0
      requiresBooking: false,
      hasVariants: true,
      variantAxes: [
        VariantAxis(
          name: 'Color',
          values: ['Negro', 'Blanco'],
          position: 0,
        ),
        VariantAxis(
          name: 'Talla',
          values: ['M', 'L'],
          position: 1,
        ),
      ],
      variants: [
        ItemVariant(
          id: 'v1',
          sku: 'POLO-BLK-M',
          price: 20.0,
          stockQuantity: 15,
          isActive: true,
          axisValues: {'Color': 'Negro', 'Talla': 'M'},
        ),
        ItemVariant(
          id: 'v2',
          sku: 'POLO-WHT-L',
          price: 25.0,
          stockQuantity: 10,
          isActive: true,
          axisValues: {'Color': 'Blanco', 'Talla': 'L'},
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ItemDetailScreen(
            storeId: 'store-1',
            item: variantItem,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Price section reflects range
    expect(find.text('RANGO DE PRECIOS'), findsOneWidget);
    expect(find.text('\$20.00 - \$25.00'), findsOneWidget);

    // 2. Verify Stock Card shows aggregate stock and NOT 'Agotado'
    expect(find.text('Stock (2 var.)'), findsOneWidget);
    expect(find.text('25 unidades'), findsOneWidget);
    expect(find.text('Agotado'), findsNothing);

    // 3. Verify Variants section is visible
    expect(find.text('VARIANTES DEL PRODUCTO'), findsOneWidget);
    expect(find.text('2 de 2 activas'), findsOneWidget);

    // 4. Verify axes chips
    expect(find.text('Color: Negro, Blanco'), findsOneWidget);
    expect(find.text('Talla: M, L'), findsOneWidget);

    // 5. Verify individual variant details
    expect(find.text('Negro / M'), findsOneWidget);
    expect(find.text('SKU: POLO-BLK-M'), findsOneWidget);
    expect(find.text('15 en stock'), findsOneWidget);

    expect(find.text('Blanco / L'), findsOneWidget);
    expect(find.text('SKU: POLO-WHT-L'), findsOneWidget);
    expect(find.text('10 en stock'), findsOneWidget);
  });

  testWidgets(
      'ItemDetailScreen for non-variant item does not display variants section',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const normalItem = Item(
      id: 'item-normal-1',
      title: 'Taza de Cerámica',
      description: 'Taza personalizada.',
      price: 8.0,
      mainImage: 'https://images.tulojita.com/taza.jpg',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 40,
      requiresBooking: false,
      hasVariants: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ItemDetailScreen(
            storeId: 'store-1',
            item: normalItem,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VARIANTES DEL PRODUCTO'), findsNothing);
    expect(find.text('Stock Disponible'), findsOneWidget);
    expect(find.text('40 unidades'), findsOneWidget);
    expect(find.text('\$8.00'), findsOneWidget);
  });
}
