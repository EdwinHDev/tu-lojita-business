import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/data/repositories/item_repository_impl.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_catalog_summary.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_owner_stats.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';
import 'package:tu_lojita_business/features/items/domain/repositories/item_repository.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_owner_stats_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_promotion_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_detail_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/screens/item_form_screen.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/detail/item_overview_bento_grid.dart';
import 'widget_test.dart';

class _CapturingHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  _CapturingHttpAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  final User _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() => Authenticated(_user);
}

class _FakeExchangeRateNotifier extends ExchangeRateNotifier {
  final ExchangeRateConfig _config;
  int refreshCalls = 0;

  _FakeExchangeRateNotifier(this._config);

  @override
  Future<ExchangeRateConfig> build() async => _config;

  @override
  Future<void> refreshRate() async {
    refreshCalls++;
    state = AsyncData(_config);
  }
}

class _FakeStoreDetailsNotifier extends StoreDetailsNotifier {
  @override
  StoreDetailsState build() => const StoreDetailsState();

  @override
  Future<void> loadData(String storeId, {bool force = false}) async {}

  @override
  Future<void> refresh(String storeId) async {}
}

class _SpyItemRepository implements ItemRepository {
  Item currentItem;
  Item? nextRefreshedItem;
  final bool failOwnerStats;
  int getItemCalls = 0;
  int getOwnerStatsCalls = 0;
  final List<({String id, Map<String, dynamic> data})> updateCalls = [];

  _SpyItemRepository({
    required this.currentItem,
    this.nextRefreshedItem,
    this.failOwnerStats = false,
  });

  @override
  Future<Item> getItemById(String id) async {
    getItemCalls++;
    return nextRefreshedItem ?? currentItem;
  }

  @override
  Future<ItemOwnerStats> getItemOwnerStats(String id) async {
    getOwnerStatsCalls++;
    if (failOwnerStats) {
      throw DioException(
        requestOptions: RequestOptions(path: '/items/$id/owner-stats'),
        response: Response(
          requestOptions: RequestOptions(path: '/items/$id/owner-stats'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return const ItemOwnerStats(
      unitsSold: 18,
      ordersCount: 9,
      favoritesCount: 12,
      grossRevenue: 540.0,
      netRevenue: 513.0,
      canViewFinancials: true,
    );
  }

  @override
  Future<Item> updateItem(
    String id,
    Map<String, dynamic> itemData, {
    List<File>? newImages,
    int mainImageIndex = 0,
  }) async {
    updateCalls.add((id: id, data: itemData));
    if (itemData.containsKey('isActive')) {
      currentItem = currentItem.copyWith(isActive: itemData['isActive'] as bool);
    }
    if (itemData.containsKey('price')) {
      final newBase = (itemData['price'] as num).toDouble();
      final newDisc = (itemData['discountPrice'] as num?)?.toDouble();
      currentItem = currentItem.copyWith(
        basePrice: newBase,
        price: newBase,
        discountPrice: newDisc != null && newDisc > 0 ? newDisc : null,
      );
    }
    if (itemData.containsKey('variants') && itemData['variants'] is List) {
      final rawList = itemData['variants'] as List;
      final updatedVariants = <ItemVariant>[];
      for (int i = 0; i < currentItem.variants.length; i++) {
        final v = currentItem.variants[i];
        final match = rawList.cast<Map<String, dynamic>?>().firstWhere(
              (m) => m != null && m['id'] == v.id,
              orElse: () => null,
            );
        if (match != null) {
          updatedVariants.add(
            ItemVariant(
              id: v.id,
              sku: v.sku,
              basePrice: match['price'] != null
                  ? (match['price'] as num).toDouble()
                  : v.basePrice,
              price: match['price'] != null
                  ? (match['price'] as num).toDouble()
                  : v.price,
              discountPrice: v.discountPrice,
              stockQuantity: match['stockQuantity'] != null
                  ? (match['stockQuantity'] as num).toDouble()
                  : v.stockQuantity,
              isActive: match['isActive'] as bool? ?? v.isActive,
              axisValues: v.axisValues,
              imageUrl: v.imageUrl,
            ),
          );
        } else {
          updatedVariants.add(v);
        }
      }
      currentItem = currentItem.copyWith(variants: updatedVariants);
    }
    return currentItem;
  }

  @override
  Future<ItemCatalogSummary> getStoreCatalogSummary(String storeId) async =>
      ItemCatalogSummary.fromItems([currentItem]);

  @override
  Future<List<Item>> getItemsByStore(String storeId) async => [currentItem];

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
      (items: [currentItem], total: 1);

  @override
  Future<Item> createItem(
    Map<String, dynamic> itemData,
    List<File> images, {
    int mainImageIndex = 0,
  }) async =>
      currentItem;

  @override
  Future<void> deleteImages(List<String> imageUrls) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<List<PropertyTemplate>> getCategoryTemplates(String categoryId) async =>
      const [];
}

User _ownerUser() => const User(
      id: 'owner-1',
      email: 'owner@tulojita.com',
      firstName: 'Ana',
      lastName: 'Torres',
      role: 'COMPANY',
      hasCompany: true,
    );

User _restrictedCollabUser({List<String> permissions = const ['inventory:view']}) =>
    User(
      id: 'collab-1',
      email: 'staff@tulojita.com',
      firstName: 'Luis',
      lastName: 'Pérez',
      role: 'COLLABORATOR',
      isCollaborator: true,
      hasFullBranchAccess: true,
      permissions: permissions,
    );

Item _buildProductItem({
  bool isActive = true,
  bool isFeatured = false,
  double? discountPrice,
  PriceType priceType = PriceType.fixed,
}) {
  return Item(
    id: 'item-prod-1',
    title: 'Café de Altura Molido Premium',
    description: 'Tueste medio artesanal de Mérida en empaque hermético.',
    basePrice: 30.0,
    commissionRate: 10.0,
    commissionAmount: 3.0,
    price: 33.0,
    priceType: priceType,
    mainImage: '/uploads/cafe.jpg',
    images: const ['/uploads/cafe.jpg', '/uploads/cafe2.jpg'],
    isFeatured: isFeatured,
    discountPrice: discountPrice,
    itemType: ItemType.product,
    trackInventory: true,
    stockQuantity: 14,
    requiresBooking: true,
    bookingType: 'PRE_ORDER',
    preorderConfig: const {
      'depositType': 'PERCENTAGE',
      'depositValue': 40,
      'estimatedLeadDaysMin': 5,
      'estimatedLeadDaysMax': 10,
    },
    allowInstallments: true,
    lateFeePercentage: 5.0,
    isActive: isActive,
    isAgeRestricted: true,
    hasVariants: true,
    favoritesCount: 12,
    attributes: const {
      'properties': [
        {'key': 'Origen', 'value': 'Mérida'},
        {'key': 'Peso', 'value': '500g'},
      ],
    },
    customizationGroups: const [
      CustomizationGroup(
        id: 'grp-1',
        name: 'Tipo de Molienda',
        minSelect: 1,
        maxSelect: 1,
        options: [
          CustomizationOption(id: 'opt-1', name: 'Molienda Fina', price: 0),
          CustomizationOption(id: 'opt-2', name: 'Empaque de Regalo', price: 2.5),
        ],
      ),
    ],
    variantAxes: const [
      VariantAxis(id: 'ax-1', name: 'Tamaño', values: ['250g', '500g']),
    ],
    variants: const [
      ItemVariant(
        id: 'var-1',
        sku: 'CAFE-250',
        basePrice: 18.0,
        price: 19.8,
        stockQuantity: 8,
        isActive: true,
        axisValues: {'Tamaño': '250g'},
      ),
      ItemVariant(
        id: 'var-2',
        sku: 'CAFE-500',
        basePrice: 30.0,
        price: 33.0,
        stockQuantity: 6,
        isActive: true,
        axisValues: {'Tamaño': '500g'},
      ),
    ],
  );
}

Item _buildSlotServiceItem({String locationType = 'CUSTOMER_CHOICE'}) {
  return Item(
    id: 'item-srv-1',
    title: 'Estética Canina Completa y Spa',
    description: 'Baño terapéutico, corte higiénico y cepillado profesional.',
    basePrice: 25.0,
    commissionRate: 10.0,
    commissionAmount: 2.5,
    price: 27.5,
    mainImage: '/uploads/spa.jpg',
    images: const ['/uploads/spa.jpg'],
    isFeatured: false,
    itemType: ItemType.service,
    trackInventory: false,
    requiresBooking: true,
    bookingType: 'TIME_SLOT',
    slotConfig: {
      'serviceLocationType': locationType,
      'serviceDurationMinutes': 90,
      'minNoticeHours': 4,
    },
    allowInstallments: false,
    isActive: true,
    favoritesCount: 7,
  );
}

Widget _wrapDetailHarness({
  required Widget home,
  required User user,
  required ExchangeRateConfig rateConfig,
  required _SpyItemRepository repo,
  ItemOwnerStats stats = const ItemOwnerStats(
    unitsSold: 18,
    ordersCount: 9,
    favoritesCount: 12,
    grossRevenue: 540.0,
    netRevenue: 513.0,
    canViewFinancials: true,
  ),
  ItemPromotionInfo? promoInfo,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(user)),
      exchangeRateProvider.overrideWith(() => _FakeExchangeRateNotifier(rateConfig)),
      itemRepositoryProvider.overrideWithValue(repo),
      storeDetailsProvider.overrideWith(() => _FakeStoreDetailsNotifier()),
      itemOwnerStatsProvider.overrideWith((ref, id) async => stats),
      itemPromotionByItemProvider.overrideWith((ref, id) async => promoInfo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: home,
    ),
  );
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    await initializeDateFormatting('es', null);
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\nAPI_KEY_IMAGES=test-key\n',
    );
  });

  group('Task 2.1: ItemOwnerStats, HTTP repository & duplicate draft mode', () {
    test('ItemOwnerStats.fromJson parses full and financially redacted payloads', () {
      final full = ItemOwnerStats.fromJson(const {
        'unitsSold': 22,
        'ordersCount': 11,
        'favoritesCount': 9,
        'grossRevenue': 660.5,
        'netRevenue': 620.25,
        'canViewFinancials': true,
      });
      expect(full.unitsSold, 22);
      expect(full.ordersCount, 11);
      expect(full.favoritesCount, 9);
      expect(full.grossRevenue, 660.5);
      expect(full.netRevenue, 620.25);
      expect(full.canViewFinancials, isTrue);

      final redacted = ItemOwnerStats.fromJson(const {
        'unitsSold': '10',
        'ordersCount': '4',
        'favoritesCount': '3',
        'grossRevenue': null,
        'netRevenue': null,
        'canViewFinancials': false,
      });
      expect(redacted.unitsSold, 10);
      expect(redacted.ordersCount, 4);
      expect(redacted.favoritesCount, 3);
      expect(redacted.grossRevenue, isNull);
      expect(redacted.netRevenue, isNull);
      expect(redacted.canViewFinancials, isFalse);
    });

    test('ItemRepositoryImpl queries GET /items/:id/owner-stats and creates duplicate reusing existingImages', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.tulojita.com/api/v1'));
      final adapter = _CapturingHttpAdapter((options) async {
        if (options.method == 'GET' &&
            options.path == '/items/item-prod-1/owner-stats') {
          return ResponseBody.fromString(
            jsonEncode({
              'unitsSold': 15,
              'ordersCount': 6,
              'favoritesCount': 8,
              'grossRevenue': 300.0,
              'netRevenue': 285.0,
              'canViewFinancials': true,
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'id': 'item-dup-1',
            'title': 'Café (Copia)',
            'description': 'Desc',
            'price': 33,
            'mainImage': '/uploads/cafe.jpg',
            'images': ['/uploads/cafe.jpg'],
            'isFeatured': false,
            'itemType': 'PRODUCT',
            'trackInventory': true,
            'requiresBooking': false,
          }),
          201,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
      dio.httpClientAdapter = adapter;

      final repo = ItemRepositoryImpl(dio);
      final stats = await repo.getItemOwnerStats('item-prod-1');
      expect(stats.unitsSold, 15);
      expect(stats.netRevenue, 285.0);

      final created = await repo.createItem(
        {
          'storeId': 'store-1',
          'title': 'Café (Copia)',
          'existingImages': ['/uploads/cafe.jpg'],
        },
        const [],
      );
      expect(created.id, 'item-dup-1');
      final postReq = adapter.requests.last;
      expect(postReq.method, 'POST');
      expect(postReq.data['mainImage'], '/uploads/cafe.jpg');
      expect(postReq.data['images'], ['/uploads/cafe.jpg']);
    });

    testWidgets('initForDuplicating prepares brand-new draft (itemId == null) and AppBar Duplicar', (tester) async {
      final source = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: source);
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(_ownerUser())),
          itemRepositoryProvider.overrideWithValue(repo),
          storeDetailsProvider.overrideWith(() => _FakeStoreDetailsNotifier()),
        ],
      );
      addTearDown(container.dispose);

      container.read(itemFormProvider.notifier).initForDuplicating(source);
      final formState = container.read(itemFormProvider);
      expect(formState.itemId, isNull);
      expect(formState.title, '${source.title} (Copia)');
      expect(formState.existingImages, source.images);
      expect(formState.variants.length, 2);
      expect(formState.variants.first.id, isNull);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ItemFormScreen(storeId: 'store-1', duplicateFrom: source),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duplicar Producto'), findsOneWidget);
    });
  });

  group('Task 3.1 & 3.2: Modular Bento cards, DualPriceText, Service modality & RBAC', () {
    testWidgets('Owner sees BCV pill, dual prices, unit profitability, pre-order, variants, and option add-ons', (tester) async {
      final product = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: product),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
          promoInfo: const ItemPromotionInfo(
            hasActivePromotion: false,
            pendingPromotion: {'durationDays': 7},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tasa BCV: Bs.'), findsOneWidget);
      expect(find.text('Rentabilidad por unidad'), findsOneWidget);
      expect(find.text('Precio público'), findsOneWidget);
      expect(find.text('Tu ingreso neto'), findsOneWidget);
      expect(find.text('Solicitud en revisión'), findsOneWidget);
      expect(find.text('Preventa (Bajo Demanda)'), findsOneWidget);
      expect(find.text('Anticipo 40%'), findsOneWidget);
      expect(find.text('Apto para Cuotas'), findsOneWidget);
      expect(find.text('+18'), findsOneWidget);
      expect(find.text('Ajustar Precio'), findsOneWidget);
      expect(find.text('Gestionar Variantes'), findsOneWidget);
      expect(find.text('Editar Artículo'), findsOneWidget);
      expect(find.text('Pausar'), findsWidgets);
      expect(find.textContaining('Bs.'), findsWidgets);
    });

    testWidgets('Restricted collaborator hides financial rows, promotion banner, and edit/delete actions', (tester) async {
      final product = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: product),
          user: _restrictedCollabUser(
            permissions: const ['inventory:view', 'inventory:change_price'],
          ),
          rateConfig: bcvConfig,
          repo: repo,
          stats: const ItemOwnerStats(
            unitsSold: 18,
            ordersCount: 9,
            favoritesCount: 12,
            grossRevenue: null,
            netRevenue: null,
            canViewFinancials: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Operational metrics and price-change button remain visible
      expect(find.text('18'), findsOneWidget);
      expect(find.text('Ajustar Precio'), findsOneWidget);

      // Financial breakdown and product-editing controls are hidden
      expect(find.text('Rentabilidad por unidad'), findsNothing);
      expect(find.text('Ingresos brutos'), findsNothing);
      expect(find.text('Neto acumulado'), findsNothing);
      expect(find.text('Promocionar en el Home'), findsNothing);
      expect(find.text('Editar Artículo'), findsNothing);
      expect(find.byTooltip('Opciones del artículo'), findsNothing);
    });

    testWidgets('ItemPromotionBannerCard displays active state and non-monetary Free/disabled currency renders cleanly', (tester) async {
      final freeItem = _buildProductItem(
        priceType: PriceType.free,
        isFeatured: true,
      );
      final repo = _SpyItemRepository(currentItem: freeItem);
      final disabledConfig = ExchangeRateConfig.disabled();

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: freeItem),
          user: _ownerUser(),
          rateConfig: disabledConfig,
          repo: repo,
          promoInfo: const ItemPromotionInfo(
            hasActivePromotion: true,
            activePromotion: {'expiresAt': '2026-12-20T12:00:00Z'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('Promoción Activa en el Home'), findsOneWidget);
      expect(find.textContaining('Tasa BCV:'), findsNothing);
    });

    testWidgets('Service slotConfig renders modality label instead of generic reservation text & shimmer builds cleanly', (tester) async {
      final serviceItem = _buildSlotServiceItem(locationType: 'CUSTOMER_CHOICE');
      final repo = _SpyItemRepository(currentItem: serviceItem);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: serviceItem),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Turnos y Modalidad'), findsOneWidget);
      expect(find.text('A elección del cliente'), findsOneWidget);
      expect(find.textContaining('90 min'), findsOneWidget);

      // Shimmer skeleton smoke test
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ItemDetailLoadingSkeleton())),
      );
      expect(find.byType(ItemDetailLoadingSkeleton), findsOneWidget);
    });

    testWidgets('Failed owner-stats and promotion requests exit shimmer immediately without Riverpod 3 retry stall', (tester) async {
      final product = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: product, failOwnerStats: true);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      final failDio = Dio(BaseOptions(baseUrl: 'https://api.tulojita.com/api/v1'));
      failDio.httpClientAdapter = _CapturingHttpAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Cannot GET ${options.path}'}),
          404,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeAuthNotifier(_ownerUser())),
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(bcvConfig)),
            itemRepositoryProvider.overrideWithValue(repo),
            dioProvider.overrideWithValue(failDio),
            storeDetailsProvider.overrideWith(() => _FakeStoreDetailsNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ItemDetailScreen(storeId: 'store-1', item: product),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Called once without exponential retries, exited shimmer to fallback
      expect(repo.getOwnerStatsCalls, 1);
      expect(
        find.text('No se pudieron cargar las métricas de ventas ahora.'),
        findsOneWidget,
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Promocionar en el Home'), findsOneWidget);
    });
  });

  group('Task 4.1: Quick controls, confirmation dialogs, RefreshIndicator & in-place edit reload', () {
    testWidgets('Pausar triggers confirmation dialog and toggles active status in place', (tester) async {
      final product = _buildProductItem(isActive: true);
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: product),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pausar').last);
      await tester.pumpAndSettle();

      expect(find.text('¿Pausar artículo?'), findsOneWidget);
      await tester.tap(find.text('Despublicar'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.last.data['isActive'], isFalse);
      expect(find.text('Publicar'), findsAtLeastNWidgets(1));
    });

    testWidgets('Quick price sheet previews Bs. and persists price update without leaving screen', (tester) async {
      final product = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: product),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar Precio'));
      await tester.pumpAndSettle();

      final baseField = find.widgetWithText(TextField, 'Precio base (USD)');
      await tester.enterText(baseField, '40.00');
      await tester.pump();
      expect(find.textContaining('~ Bs.'), findsWidgets);

      await tester.tap(find.text('Guardar Precio'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.last.data['price'], 40.0);
    });

    testWidgets('Quick variants sheet updates variant stock and active state in place', (tester) async {
      final product = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: product),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      final manageBtn = find.text('Gestionar Variantes');
      await tester.tap(manageBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.last.data['variants'], isList);
    });

    testWidgets('Quick stock sheet shows error feedback on invalid/empty input and saves valid stock', (tester) async {
      final singleSkuItem = _buildProductItem().copyWith(
        hasVariants: false,
        variants: const [],
        stockQuantity: 10,
      );
      final repo = _SpyItemRepository(currentItem: singleSkuItem);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: singleSkuItem),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustar').first);
      await tester.pumpAndSettle();

      final stockField = find.widgetWithText(TextField, 'Cantidad disponible');
      await tester.enterText(stockField, '-5');
      await tester.tap(find.text('Guardar Stock'));
      await tester.pump();

      expect(
        find.text('Ingresa una cantidad entera igual o mayor a 0.'),
        findsOneWidget,
      );
      expect(repo.updateCalls, isEmpty);

      await tester.enterText(stockField, '22');
      await tester.tap(find.text('Guardar Stock'));
      await tester.pumpAndSettle();

      expect(repo.updateCalls.last.data['stockQuantity'], 22);
    });

    testWidgets('Pull-to-refresh and returning from Edit wizard reload item in place without popping', (tester) async {
      final initial = _buildProductItem();
      final refreshed = initial.copyWith(title: 'Café Actualizado en Sitio');
      final repo = _SpyItemRepository(
        currentItem: initial,
        nextRefreshedItem: refreshed,
      );
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      final router = GoRouter(
        initialLocation: '/detail',
        routes: [
          GoRoute(
            path: '/detail',
            builder: (context, state) =>
                ItemDetailScreen(storeId: 'store-1', item: initial),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/items/new',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(true),
                child: const Text('Completar Edición'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeAuthNotifier(_ownerUser())),
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(bcvConfig)),
            itemRepositoryProvider.overrideWithValue(repo),
            storeDetailsProvider.overrideWith(() => _FakeStoreDetailsNotifier()),
            itemOwnerStatsProvider.overrideWith(
              (ref, id) async => const ItemOwnerStats(
                unitsSold: 5,
                ordersCount: 2,
                favoritesCount: 1,
                grossRevenue: 100,
                netRevenue: 95,
                canViewFinancials: true,
              ),
            ),
            itemPromotionByItemProvider.overrideWith((ref, id) async => null),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger pull-to-refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(repo.getItemCalls, greaterThanOrEqualTo(1));
      expect(find.text('Café Actualizado en Sitio'), findsWidgets);

      // Navigate to Edit and return true -> reloads in place instead of popping
      await tester.tap(find.text('Editar Artículo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completar Edición'));
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(repo.getItemCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('Hero gallery swipes, opens InteractiveViewer lightbox, and reveals collapsed title on scroll', (tester) async {
      final product = _buildProductItem();
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        _wrapDetailHarness(
          home: ItemDetailScreen(storeId: 'store-1', item: product),
          user: _ownerUser(),
          rateConfig: bcvConfig,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);

      await tester.tap(find.byType(PageView));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);

      // Scroll down past hero gallery to verify collapsed app bar reveals title
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text(product.title), findsAtLeastNWidgets(1));
    });
  });

  group('Task 5.1: Narrow 320px viewport @ 1.35x text scale stress tests', () {
    testWidgets('Product ItemDetailScreen has zero overflow at 320px @ 1.35x', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final product = _buildProductItem(discountPrice: 28.0);
      final repo = _SpyItemRepository(currentItem: product);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 740),
            textScaler: TextScaler.linear(1.35),
          ),
          child: _wrapDetailHarness(
            home: ItemDetailScreen(storeId: 'store-1', item: product),
            user: _ownerUser(),
            rateConfig: bcvConfig,
            repo: repo,
            promoInfo: const ItemPromotionInfo(hasActivePromotion: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Service ItemDetailScreen has zero overflow at 320px @ 1.35x', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _buildSlotServiceItem(locationType: 'HOME_SERVICE');
      final repo = _SpyItemRepository(currentItem: service);
      const bcvConfig = ExchangeRateConfig(enabled: true, rate: 50.0);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 740),
            textScaler: TextScaler.linear(1.35),
          ),
          child: _wrapDetailHarness(
            home: ItemDetailScreen(storeId: 'store-1', item: service),
            user: _ownerUser(),
            rateConfig: bcvConfig,
            repo: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
