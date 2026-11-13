import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_category.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_catalog_summary.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_owner_stats.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';
import 'package:tu_lojita_business/features/items/domain/repositories/item_repository.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_form_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/wizard_contextual_help.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  const testStoreId = 'test-store-bento';

  Widget buildTestApp({
    required Widget home,
    double textScale = 1.0,
    ExchangeRateConfig? rateConfig,
  }) {
    return ProviderScope(
      overrides: [
        storeDetailsProvider.overrideWith(() => _MockStoreDetailsNotifier()),
        itemRepositoryProvider.overrideWithValue(_MockItemRepository()),
        exchangeRateProvider.overrideWith(
          () => _MockExchangeRateNotifier(
            rateConfig ??
                const ExchangeRateConfig(
                  enabled: true,
                  rate: 45.50,
                  symbol: 'Bs.',
                ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: home,
      ),
    );
  }

  testWidgets(
      '1. Step 1: Selecting Servicio in Bento type selector updates stepper labels and opens contextual help sheet',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        home: const ItemFormScreen(storeId: testStoreId),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Bento cards for Producto Físico and Servicio exist
    expect(find.byKey(const Key('wizard_type_product_card')), findsOneWidget);
    expect(find.byKey(const Key('wizard_type_service_card')), findsOneWidget);
    expect(find.text('Opciones'), findsOneWidget);

    // Tap Servicio card
    await tester.tap(find.byKey(const Key('wizard_type_service_card')));
    await tester.pumpAndSettle();

    // Step 3 label in stepper should adapt to Agenda
    expect(find.text('Agenda'), findsOneWidget);
    expect(
      find.textContaining('Modo Servicio activo:'),
      findsOneWidget,
    );

    // Tap contextual help button and verify bottom sheet opens
    final helpButtons = find.byType(WizardContextualHelpButton);
    expect(helpButtons, findsAtLeastNWidgets(1));
    await tester.tap(helpButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Entendido'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      '2. Step 2: Entering base price and discount price with active BCV rate renders live ~ Bs. helpers, -20% badge, and dual commission breakdown',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const existingDraft = Item(
      id: 'draft-1',
      title: 'Zapatos Running Pro',
      description: 'Zapatos deportivos con suela amortiguada de alta resistencia.',
      price: 25.0,
      discountPrice: 20.0,
      priceType: PriceType.fixed,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      categoryId: 'cat-1',
      trackInventory: true,
      stockQuantity: 15,
      requiresBooking: false,
    );

    await tester.pumpWidget(
      buildTestApp(
        home: ItemFormScreen(storeId: testStoreId, item: existingDraft),
      ),
    );
    await tester.pumpAndSettle();

    // Jump directly to Step 2 (index 1)
    await tester.tap(find.byKey(const Key('wizard_step_tab_1')));
    await tester.pumpAndSettle();

    // Set commission ranges on provider so breakdown card renders
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ItemFormScreen)),
    );
    container.read(itemFormProvider.notifier).state =
        container.read(itemFormProvider).copyWith(
      commissionRanges: [
        {
          'minAmount': 0,
          'maxAmount': 1000,
          'singlePaymentRate': 10.0,
          'installmentPaymentRate': 15.0,
        },
      ],
    );
    await tester.pumpAndSettle();

    // Live BCV helpers for base price ($25 * 45.50 = 1.137,50) and discount ($20 * 45.50 = 910,00)
    expect(find.byKey(const Key('wizard_base_price_bcv_helper')), findsOneWidget);
    expect(find.byKey(const Key('wizard_discount_price_bcv_helper')), findsOneWidget);
    expect(find.byKey(const Key('wizard_discount_savings_badge')), findsOneWidget);
    expect(
      find.textContaining('Oferta activa: -20% de ahorro visible para el comprador'),
      findsOneWidget,
    );

    // Commission breakdown card shows dual prices
    expect(find.byKey(const Key('wizard_commission_breakdown_card')), findsOneWidget);
    expect(find.textContaining('Bs.'), findsAtLeastNWidgets(3));
  });

  testWidgets(
      '3. Step 3: Enabling preventa renders upfront/balance financial summary in USD and Bs.; service mode shows 1-tap Lun-Vie template button',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const existingItem = Item(
      id: 'item-step3',
      title: 'Torta Personalizada',
      description: 'Torta por encargo decorada a mano para eventos.',
      price: 40.0,
      priceType: PriceType.fixed,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      categoryId: 'cat-1',
      trackInventory: true,
      requiresBooking: true,
    );

    await tester.pumpWidget(
      buildTestApp(
        home: ItemFormScreen(storeId: testStoreId, item: existingItem),
      ),
    );
    await tester.pumpAndSettle();

    // Jump to Step 3 (index 2)
    await tester.tap(find.byKey(const Key('wizard_step_tab_2')));
    await tester.pumpAndSettle();

    // Preventa financial summary card is visible with USD + Bs.
    expect(find.byKey(const Key('wizard_preorder_financial_summary')), findsOneWidget);
    expect(find.text('Abono al reservar:'), findsOneWidget);
    expect(find.text('Saldo contra entrega:'), findsOneWidget);

    // Switch to Service mode and verify 1-tap Lun-Vie slots template button
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ItemFormScreen)),
    );
    container.read(itemFormProvider.notifier).onItemTypeChanged(ItemType.service);
    container.read(itemFormProvider.notifier).onRequiresBookingChanged(true);
    await tester.pumpAndSettle();

    final quickSlotsBtn = find.byKey(const Key('wizard_quick_weekday_slots_button'));
    expect(quickSlotsBtn, findsOneWidget);

    await tester.ensureVisible(quickSlotsBtn);
    await tester.tap(quickSlotsBtn);
    await tester.pumpAndSettle();

    final slots = container.read(itemFormProvider).slotConfig['slots'] as List;
    expect(slots.length, 5);
    expect(find.text('Jornada Habitual'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      '4. Step 4 & Edit Mode: Opening with existing item unlocks all 4 tabs, shows quick-save action, and renders Owner Readiness Card with quick-jump buttons',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const existingItem = Item(
      id: 'item-edit-4',
      title: 'Audífonos Bluetooth ANC',
      description: 'Cancelación activa de ruido y 30 horas de batería.',
      price: 50.0,
      priceType: PriceType.fixed,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      categoryId: 'cat-1',
      trackInventory: true,
      stockQuantity: 12,
      requiresBooking: false,
    );

    await tester.pumpWidget(
      buildTestApp(
        home: ItemFormScreen(storeId: testStoreId, item: existingItem),
      ),
    );
    await tester.pumpAndSettle();

    // Quick save button is visible in AppBar in edit mode
    expect(find.byKey(const Key('wizard_quick_save_button')), findsOneWidget);

    // Jump straight from Step 1 to Step 4 (index 3) without stepping through 2 & 3
    await tester.tap(find.byKey(const Key('wizard_step_tab_3')));
    await tester.pumpAndSettle();

    expect(find.text('Paso 4 de 4'), findsOneWidget);
    expect(find.byKey(const Key('wizard_owner_readiness_card')), findsOneWidget);
    expect(find.text('Tu Ganancia Neta:'), findsOneWidget);
    expect(find.text('Precio Público (Contado):'), findsOneWidget);
    expect(find.byKey(const Key('wizard_preview_main_price_bcv_helper')), findsOneWidget);

    // Quick jump chip back to Step 2 (Editar Precios)
    await tester.tap(find.byKey(const Key('wizard_jump_step_1')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 4'), findsOneWidget);
  });

  testWidgets(
      '5. Zero RenderFlex overflow across all 4 steps at 320px width and 1.35x text scale',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const existingItem = Item(
      id: 'item-320px',
      title: 'Combo Familiar Especial con Extras',
      description: 'Descripción completa para validar diseño responsivo a 320px.',
      price: 35.0,
      discountPrice: 28.0,
      priceType: PriceType.fixed,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      categoryId: 'cat-1',
      trackInventory: true,
      stockQuantity: 20,
      allowInstallments: true,
      lateFeePercentage: 5.0,
      requiresBooking: true,
      customizationGroups: [
        CustomizationGroup(
          id: 'g1',
          name: 'Extras',
          minSelect: 0,
          maxSelect: 2,
          options: [
            CustomizationOption(
              id: 'o1',
              name: 'Queso Extra Especial',
              price: 2.5,
              minQuantity: 0,
              maxQuantity: 2,
              defaultQuantity: 0,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        textScale: 1.35,
        home: ItemFormScreen(storeId: testStoreId, item: existingItem),
      ),
    );
    await tester.pumpAndSettle();

    // Step 2 at 320px @ 1.35x
    await tester.tap(find.byKey(const Key('wizard_step_tab_1')));
    await tester.pumpAndSettle();

    // Step 3 at 320px @ 1.35x
    await tester.tap(find.byKey(const Key('wizard_step_tab_2')));
    await tester.pumpAndSettle();

    // Step 4 at 320px @ 1.35x
    await tester.tap(find.byKey(const Key('wizard_step_tab_3')));
    await tester.pumpAndSettle();
  });

  testWidgets(
      '6. AppBar renders wizard title and BCV rate stacked vertically without collision at 320px @ 1.35x, 360px and 800px',
      (tester) async {
    final viewports = [
      (size: const Size(320, 640), scale: 1.35, desc: '320px @ 1.35x'),
      (size: const Size(360, 800), scale: 1.0, desc: '360px'),
      (size: const Size(800, 1200), scale: 1.0, desc: '800px'),
    ];

    for (final vp in viewports) {
      tester.view.physicalSize = vp.size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestApp(
          textScale: vp.scale,
          home: const ItemFormScreen(storeId: testStoreId),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'No exception at ${vp.desc}');
      expect(find.text('Nuevo Producto'), findsOneWidget, reason: 'Wizard title present at ${vp.desc}');
      expect(find.text('Tasa BCV: Bs. 45,50'), findsOneWidget, reason: 'BCV rate present at ${vp.desc}');

      // Verify vertical stacking: title Y < BCV rate Y
      final titlePos = tester.getTopLeft(find.text('Nuevo Producto'));
      final ratePos = tester.getTopLeft(find.text('Tasa BCV: Bs. 45,50'));
      expect(titlePos.dy < ratePos.dy, isTrue, reason: 'Title should be stacked above BCV pill at ${vp.desc}');
    }
  });
}

class _MockExchangeRateNotifier extends ExchangeRateNotifier {
  final ExchangeRateConfig _config;
  _MockExchangeRateNotifier(this._config);

  @override
  Future<ExchangeRateConfig> build() async => _config;
}

class _MockStoreDetailsNotifier extends StoreDetailsNotifier {
  @override
  StoreDetailsState build() {
    return const StoreDetailsState(
      storeData: {
        'test-store-bento': StoreDetailsData(
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
  Future<Item> createItem(
    Map<String, dynamic> itemData,
    List<File> images, {
    int mainImageIndex = 0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteImages(List<String> imageUrls) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<ItemOwnerStats> getItemOwnerStats(String id) async =>
      const ItemOwnerStats();

  @override
  Future<ItemCatalogSummary> getStoreCatalogSummary(String storeId) async =>
      const ItemCatalogSummary();

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
    bool? isActive,
    bool? onlyOutOfStock,
    bool? hasDiscount,
    ItemType? itemType,
  }) async =>
      (items: <Item>[], total: 0);

  @override
  Future<Item> getItemById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Item> updateItem(
    String id,
    Map<String, dynamic> itemData, {
    List<File>? newImages,
    int mainImageIndex = 0,
  }) async {
    throw UnimplementedError();
  }
}
