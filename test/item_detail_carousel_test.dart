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

  const testItem = Item(
    id: 'item-carousel-1',
    title: 'Producto con Galería',
    description: 'Descripción detallada para pruebas de carrusel.',
    price: 35.0,
    mainImage: 'https://images.tulojita.com/foto1.jpg',
    images: [
      'https://images.tulojita.com/foto1.jpg',
      'https://images.tulojita.com/foto2.jpg',
      'https://images.tulojita.com/foto3.jpg',
    ],
    isFeatured: true,
    itemType: ItemType.product,
    trackInventory: false,
    requiresBooking: false,
  );

  testWidgets(
      'ItemDetailScreen allows swiping carousel, updates indicators, and opens lightbox',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ItemDetailScreen(
            storeId: 'store-123',
            item: testItem,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial slide counter shows 1 / 3
    expect(find.text('1 / 3'), findsOneWidget);

    // Verify PageView exists
    final pageViewFinder = find.byType(PageView);
    expect(pageViewFinder, findsOneWidget);

    // Verify gradient overlay has IgnorePointer
    final ignorePointers = find.byType(IgnorePointer);
    expect(ignorePointers, findsWidgets);

    // Swipe left on the PageView to navigate to slide 2
    await tester.drag(pageViewFinder, const Offset(-400, 0));
    await tester.pumpAndSettle();

    // Verify counter updated to 2 / 3
    expect(find.text('2 / 3'), findsOneWidget);

    // Tap on the PageView to open the lightbox dialog
    await tester.tap(pageViewFinder);
    await tester.pumpAndSettle();

    // Verify InteractiveViewer is present inside dialog
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Close the lightbox dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Lightbox should be dismissed, returning to detail screen
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Producto con Galería'), findsOneWidget);
  });
}
