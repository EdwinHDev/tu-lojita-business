import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_category.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';
import 'package:tu_lojita_business/features/items/domain/repositories/item_repository.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_form_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/item_wizard_stepper.dart';
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
      'ItemFormScreen initializes as 4-step wizard with stepper, progressive validation and navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testStoreId = 'test-store-123';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeDetailsProvider.overrideWith(() => _MockStoreDetailsNotifier()),
          itemRepositoryProvider.overrideWithValue(_MockItemRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ItemFormScreen(storeId: testStoreId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Top Stepper is present with 4 steps
    expect(find.byType(ItemWizardStepper), findsOneWidget);
    expect(find.text('Básico'), findsOneWidget);
    expect(find.text('Precios'), findsOneWidget);
    expect(find.text('Opciones'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Paso 1 de 4'), findsOneWidget);

    // 2. Verify Bottom Navigation Bar shows "Cancelar" and "Siguiente: Precios"
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Siguiente: Precios'), findsOneWidget);

    // 3. Test Progressive Validation: Tapping "Siguiente" without inputs fails and stays on Step 1
    await tester.tap(find.text('Siguiente: Precios'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Ingresa un título descriptivo para el artículo'), findsOneWidget);

    // 4. Input Title, Description, and Category
    final titleField = find.widgetWithText(TextFormField, 'Título del artículo');
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, 'Camiseta Oversize Streetwear');

    final descField = find.widgetWithText(TextFormField, 'Descripción detallada');
    expect(descField, findsOneWidget);
    await tester.enterText(descField, 'Camiseta 100% de algodón peinado con corte relajado.');

    // Select category from mock store categories
    final catDropdown = find.widgetWithText(DropdownButtonFormField<String>, 'Categoría de la tienda');
    expect(catDropdown, findsOneWidget);
    await tester.tap(catDropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ropa Casual').last);
    await tester.pumpAndSettle();

    // 5. Tap "Siguiente: Precios" -> advances to Step 2!
    await tester.tap(find.text('Siguiente: Precios'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 4'), findsOneWidget);
    expect(find.text('Precios y Ofertas'), findsOneWidget);
    expect(find.text('Atrás'), findsOneWidget);
    expect(find.text('Siguiente: Opciones'), findsOneWidget);

    // 6. Test Back button -> returns to Step 1!
    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 4'), findsOneWidget);
    expect(find.text('Camiseta Oversize Streetwear'), findsOneWidget);

    // 7. Test Top Stepper quick jump: tap "Precios" directly
    await tester.tap(find.text('Precios'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 4'), findsOneWidget);

    // Enter price and stock in Step 2
    final priceField = find.widgetWithText(TextFormField, 'Precio Base');
    expect(priceField, findsOneWidget);
    await tester.enterText(priceField, '25.00');

    final stockField = find.widgetWithText(TextFormField, 'Cantidad disponible en stock');
    expect(stockField, findsOneWidget);
    await tester.enterText(stockField, '50');
    await tester.pumpAndSettle();

    // 8. Tap "Siguiente: Opciones" -> advances to Step 3!
    await tester.tap(find.text('Siguiente: Opciones'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 3 de 4'), findsOneWidget);
    expect(find.text('Opciones de Personalización y Extras'), findsOneWidget);
    expect(find.text('Siguiente: Preview'), findsOneWidget);

    // 9. Tap "Siguiente: Preview" -> advances to Step 4 (Vista Previa)!
    await tester.tap(find.text('Siguiente: Preview'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 4 de 4'), findsOneWidget);
    expect(find.text('Vista previa interactiva: Así se presentará tu artículo a los compradores en la app.'), findsOneWidget);
    expect(find.text('Camiseta Oversize Streetwear'), findsOneWidget);
    expect(find.text('\$25.00'), findsOneWidget);

    // 10. Verify final Action Button in Step 4 is "PUBLICAR ARTÍCULO"
    expect(find.text('PUBLICAR ARTÍCULO'), findsOneWidget);
  });
}

class _MockStoreDetailsNotifier extends StoreDetailsNotifier {
  @override
  StoreDetailsState build() {
    return const StoreDetailsState(
      storeData: {
        'test-store-123': StoreDetailsData(
          categories: [
            StoreCategory(
              id: 'cat-1',
              name: 'Ropa Casual',
              description: 'Prendas y accesorios casuales',
            ),
          ],
        ),
      },
    );
  }

  @override
  Future<void> loadData(String storeId, {bool force = false}) async {}

  @override
  Future<void> refresh(String storeId) async {}
}

class _MockItemRepository implements ItemRepository {
  @override
  Future<List<PropertyTemplate>> getCategoryTemplates(String categoryId) async => [];

  @override
  Future<Item> createItem(Map<String, dynamic> itemData, List<File> images, {int mainImageIndex = 0}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteImages(List<String> imageUrls) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<List<Item>> getItemsByStore(String storeId) async => [];

  @override
  Future<({List<Item> items, int total})> getItemsPaginated({
    required String storeId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? categoryId,
    String? sortBy,
    String? order,
    bool? onlyInStock,
  }) async => (items: <Item>[], total: 0);

  @override
  Future<Item> getItemById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Item> updateItem(String id, Map<String, dynamic> itemData, {List<File>? newImages, int mainImageIndex = 0}) async {
    throw UnimplementedError();
  }
}
