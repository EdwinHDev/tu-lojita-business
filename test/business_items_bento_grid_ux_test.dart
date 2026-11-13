import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_category.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/item_list_screen.dart';
import 'package:tu_lojita_business/features/items/data/repositories/item_repository_impl.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_catalog_summary.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_owner_stats.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';
import 'package:tu_lojita_business/features/items/domain/repositories/item_repository.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_notifier.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/list/item_bento_grid_card.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/list/items_bento_shimmer.dart';

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
  final List<StoreCategory> categories;

  _FakeStoreDetailsNotifier({this.categories = const []});

  @override
  StoreDetailsState build() => StoreDetailsState(
        storeData: {
          'store-1': StoreDetailsData(categories: categories),
        },
      );

  @override
  Future<void> loadData(String storeId, {bool force = false}) async {}

  @override
  Future<void> refresh(String storeId) async {}
}

class _CatalogSpyItemRepository implements ItemRepository {
  List<Item> catalogItems;
  Completer<void>? loadCompleter;
  final bool failSummary;
  final List<Map<String, dynamic>> paginatedCalls = [];
  final List<({String id, Map<String, dynamic> data})> updateCalls = [];
  int summaryCalls = 0;

  _CatalogSpyItemRepository({
    required List<Item> items,
    this.loadCompleter,
    this.failSummary = false,
  }) : catalogItems = List<Item>.from(items);

  @override
  Future<ItemCatalogSummary> getStoreCatalogSummary(String storeId) async {
    summaryCalls++;
    if (failSummary) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '/items/store/$storeId/owner-summary',
        ),
        response: Response(
          requestOptions: RequestOptions(
            path: '/items/store/$storeId/owner-summary',
          ),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return ItemCatalogSummary.fromItems(catalogItems);
  }

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
  }) async {
    paginatedCalls.add({
      'storeId': storeId,
      'searchQuery': searchQuery,
      'categoryId': categoryId,
      'sortBy': sortBy,
      'order': order,
      'onlyInStock': onlyInStock,
      'isActive': isActive,
      'onlyOutOfStock': onlyOutOfStock,
      'hasDiscount': hasDiscount,
      'itemType': itemType,
    });

    if (loadCompleter != null && !loadCompleter!.isCompleted) {
      await loadCompleter!.future;
    }

    Iterable<Item> filtered = catalogItems;
    if (isActive != null) {
      filtered = filtered.where((i) => i.isActive == isActive);
    }
    if (onlyOutOfStock == true) {
      filtered = filtered.where((i) => i.isOutOfStock);
    }
    if (hasDiscount == true) {
      filtered = filtered.where(
        (i) =>
            i.discountPrice != null &&
            i.discountPrice! > 0 &&
            i.discountPrice! < i.price,
      );
    }
    if (itemType != null) {
      filtered = filtered.where((i) => i.itemType == itemType);
    }
    if (categoryId != null) {
      filtered = filtered.where((i) => i.categoryId == categoryId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where(
        (i) => i.title.toLowerCase().contains(searchQuery.toLowerCase()),
      );
    }

    final list = filtered.toList();
    return (items: list, total: list.length);
  }

  @override
  Future<Item> updateItem(
    String id,
    Map<String, dynamic> itemData, {
    List<File>? newImages,
    int mainImageIndex = 0,
  }) async {
    updateCalls.add((id: id, data: itemData));
    final idx = catalogItems.indexWhere((i) => i.id == id);
    var target = idx >= 0 ? catalogItems[idx] : catalogItems.first;

    if (itemData.containsKey('isActive')) {
      target = target.copyWith(isActive: itemData['isActive'] as bool);
    }
    if (itemData.containsKey('price')) {
      final newBase = (itemData['price'] as num).toDouble();
      final newDisc = (itemData['discountPrice'] as num?)?.toDouble();
      final hasDisc = newDisc != null && newDisc > 0;
      target = target.copyWith(
        basePrice: newBase,
        price: newBase,
        discountPrice: hasDisc ? newDisc : null,
        clearDiscountPrice: !hasDisc,
      );
    }
    if (itemData.containsKey('stockQuantity')) {
      target = target.copyWith(
        stockQuantity: (itemData['stockQuantity'] as num).toDouble(),
      );
    }
    if (idx >= 0) {
      catalogItems[idx] = target;
    }
    return target;
  }

  @override
  Future<Item> getItemById(String id) async =>
      catalogItems.firstWhere((i) => i.id == id);

  @override
  Future<ItemOwnerStats> getItemOwnerStats(String id) async =>
      const ItemOwnerStats();

  @override
  Future<List<Item>> getItemsByStore(String storeId) async => catalogItems;

  @override
  Future<Item> createItem(
    Map<String, dynamic> itemData,
    List<File> images, {
    int mainImageIndex = 0,
  }) async =>
      catalogItems.first;

  @override
  Future<void> deleteImages(List<String> imageUrls) async {}

  @override
  Future<void> deleteItem(String id) async {
    catalogItems.removeWhere((i) => i.id == id);
  }

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

User _collaboratorUser(List<String> permissions) => User(
      id: 'collab-1',
      email: 'collab@tulojita.com',
      firstName: 'Luis',
      lastName: 'Pérez',
      role: 'COLLABORATOR',
      isCollaborator: true,
      permissions: permissions,
    );

List<Item> _buildSampleCatalog() {
  return [
    const Item(
      id: 'item-discount',
      title: 'Café Gourmet en Grano 500g Edición Especial',
      description: 'Tostado medio',
      basePrice: 19.0,
      commissionRate: 5.0,
      commissionAmount: 1.0,
      price: 20.0,
      discountPrice: 16.0,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 12,
      requiresBooking: false,
      isActive: true,
      favoritesCount: 14,
      categoryId: 'cat-1',
    ),
    const Item(
      id: 'item-variants',
      title: 'Camisa Oxford Ejecutiva',
      description: 'Algodón',
      basePrice: 24.0,
      price: 25.0,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 0,
      requiresBooking: false,
      isActive: true,
      hasVariants: true,
      favoritesCount: 5,
      categoryId: 'cat-1',
      variants: [
        ItemVariant(
          id: 'v-1',
          sku: 'CAM-S',
          basePrice: 24,
          price: 25,
          stockQuantity: 2,
          isActive: true,
          axisValues: {'Talla': 'S'},
        ),
        ItemVariant(
          id: 'v-2',
          sku: 'CAM-L',
          basePrice: 29,
          price: 30,
          stockQuantity: 1,
          isActive: true,
          axisValues: {'Talla': 'L'},
        ),
      ],
    ),
    const Item(
      id: 'item-out',
      title: 'Termo Acero Inoxidable 1L',
      description: 'Térmico',
      basePrice: 14.0,
      price: 15.0,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 0,
      requiresBooking: false,
      isActive: true,
      favoritesCount: 0,
      categoryId: 'cat-2',
    ),
    const Item(
      id: 'item-paused',
      title: 'Prensa Francesa Clásica 600ml',
      description: 'Vidrio borosilicato',
      basePrice: 18.0,
      price: 19.0,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 6,
      requiresBooking: false,
      isActive: false,
      preorderConfig: {'leadTimeDays': 3},
      favoritesCount: 2,
      categoryId: 'cat-2',
    ),
    const Item(
      id: 'item-service',
      title: 'Cata Barista Privada a Domicilio',
      description: 'Sesión guiada',
      basePrice: 40.0,
      price: 42.0,
      mainImage: '',
      images: [],
      isFeatured: false,
      itemType: ItemType.service,
      trackInventory: false,
      requiresBooking: true,
      bookingType: 'TIME_SLOT',
      slotConfig: {'serviceLocationType': 'HOME_SERVICE'},
      isActive: true,
      favoritesCount: 8,
    ),
  ];
}

Widget _buildTestHarness({
  required _CatalogSpyItemRepository repo,
  User? user,
  ExchangeRateConfig rateConfig = const ExchangeRateConfig(
    enabled: true,
    rate: 36.50,
  ),
  _FakeExchangeRateNotifier? rateNotifier,
  List<StoreCategory> categories = const [
    StoreCategory(id: 'cat-1', name: 'Especialidades', description: ''),
    StoreCategory(id: 'cat-2', name: 'Accesorios', description: ''),
  ],
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final effectiveUser = user ?? _ownerUser();
  final effectiveRateNotifier =
      rateNotifier ?? _FakeExchangeRateNotifier(rateConfig);

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(effectiveUser)),
      exchangeRateProvider.overrideWith(() => effectiveRateNotifier),
      storeDetailsProvider.overrideWith(
        () => _FakeStoreDetailsNotifier(categories: categories),
      ),
      itemRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const ItemListScreen(storeId: 'store-1'),
    ),
  );
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(
      envString: '''
API_BASE_URL=https://api.tulojita.com
API_BASE_URL_IMAGES=https://img.tulojita.com
API_KEY_IMAGES=test-key
''',
    );
    await initializeDateFormatting('es', null);
  });

  group('Repository & Notifier Catalog Summary and Filtering', () {
    test(
        'ItemRepositoryImpl queries GET /items/store/:storeId/owner-summary and forwards operational filters to GET /items',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.tulojita.com'));
      final adapter = _CapturingHttpAdapter((options) async {
        if (options.path == '/items/store/store-1/owner-summary') {
          return ResponseBody.fromString(
            jsonEncode({
              'total': 12,
              'published': 9,
              'paused': 3,
              'outOfStock': 2,
              'discounted': 4,
              'products': 10,
              'services': 2,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'data': [], 'total': 0}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      dio.httpClientAdapter = adapter;

      final repo = ItemRepositoryImpl(dio);
      final summary = await repo.getStoreCatalogSummary('store-1');
      expect(summary.total, 12);
      expect(summary.published, 9);
      expect(summary.paused, 3);
      expect(summary.outOfStock, 2);
      expect(summary.discounted, 4);
      expect(summary.products, 10);
      expect(summary.services, 2);

      await repo.getItemsPaginated(
        storeId: 'store-1',
        isActive: false,
        onlyOutOfStock: true,
        hasDiscount: true,
        itemType: ItemType.service,
        sortBy: 'favoritesCount',
        order: 'DESC',
      );

      final itemsReq = adapter.requests.last;
      expect(itemsReq.path, '/items');
      expect(itemsReq.queryParameters['isActive'], false);
      expect(itemsReq.queryParameters['onlyOutOfStock'], true);
      expect(itemsReq.queryParameters['hasDiscount'], true);
      expect(itemsReq.queryParameters['itemType'], 'SERVICE');
      expect(itemsReq.queryParameters['sort'], 'favoritesCount');
      expect(itemsReq.queryParameters['order'], 'DESC');
    });

    test(
        'ItemListNotifier upsertItem updates item in-place and removes item when it no longer matches active statusFilter',
        () async {
      final repo = _CatalogSpyItemRepository(items: _buildSampleCatalog());
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(_ownerUser())),
          itemRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(itemListProvider.notifier).loadInitial('store-1');
      var data = container.read(itemListProvider).forStore('store-1');
      expect(data.items.length, 5);
      expect(data.effectiveSummary.total, 5);

      // Filter by published
      container
          .read(itemListProvider.notifier)
          .setStatusFilter('store-1', ItemCatalogStatusFilter.published);
      await Future<void>.delayed(Duration.zero);
      data = container.read(itemListProvider).forStore('store-1');
      expect(data.items.every((i) => i.isActive), isTrue);

      // Upsert an item changing it to paused -> removed in-place from published filter
      final firstItem = data.items.first;
      container
          .read(itemListProvider.notifier)
          .upsertItem('store-1', firstItem.copyWith(isActive: false));
      data = container.read(itemListProvider).forStore('store-1');
      expect(data.items.any((i) => i.id == firstItem.id), isFalse);
    });

    test(
        'When getStoreCatalogSummary fails during loadInitial while items are still loading, effectiveSummary uses loaded items fallback instead of 0',
        () async {
      final completer = Completer<void>();
      final repo = _CatalogSpyItemRepository(
        items: _buildSampleCatalog(),
        loadCompleter: completer,
        failSummary: true,
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(_ownerUser())),
          itemRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final loadFuture =
          container.read(itemListProvider.notifier).loadInitial('store-1');
      // Let refreshSummary fail first while _fetchItems is still awaiting completer
      await Future<void>.delayed(Duration.zero);
      completer.complete();
      await loadFuture;

      final data = container.read(itemListProvider).forStore('store-1');
      expect(data.summary, isNull);
      expect(data.fallbackSummary, isNotNull);
      expect(data.effectiveSummary.total, 5);
      expect(data.effectiveSummary.published, 4);
      expect(data.effectiveSummary.paused, 1);
      expect(data.effectiveSummary.outOfStock, 1);
      expect(data.effectiveSummary.discounted, 1);
    });
  });

  group('2-Column Bento Grid Layout, Priority Badges & BCV Dual Currency', () {
    testWidgets(
        'Renders 2-column Bento grid cards with semantic emoji-free badges, BCV header pill, strike-through discount and Desde variant pricing',
        (tester) async {
      final repo = _CatalogSpyItemRepository(items: _buildSampleCatalog());
      final rateNotifier = _FakeExchangeRateNotifier(
        const ExchangeRateConfig(enabled: true, rate: 36.50),
      );

      await tester.pumpWidget(
        _buildTestHarness(repo: repo, rateNotifier: rateNotifier),
      );
      await tester.pumpAndSettle();

      // 2-column Bento cards rendered
      expect(find.byType(ItemBentoGridCard), findsWidgets);

      // Status labels appear ONLY once in unified header pills (no duplicate 2x2 KPI strip)
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Publicados'), findsOneWidget);
      expect(find.text('Pausados'), findsOneWidget);
      expect(find.text('Agotados'), findsOneWidget);
      expect(find.text('artículos en catálogo'), findsNothing);

      // FAB shows "Agregar artículo" without double "+"
      expect(find.text('Agregar artículo'), findsOneWidget);
      expect(find.text('+ Artículo'), findsNothing);

      // Zero legacy emojis
      expect(find.textContaining('🔴'), findsNothing);
      expect(find.textContaining('⚠️'), findsNothing);
      expect(find.textContaining('🟢'), findsNothing);
      expect(find.textContaining('🟣'), findsNothing);

      // Priority badges in Row 0
      expect(find.text('Oferta -20%'), findsOneWidget);
      expect(find.text('Stock bajo'), findsOneWidget);

      // Operational meta labels in Row 0
      expect(find.text('Producto · Stock: 12'), findsOneWidget);
      expect(find.text('2 var.'), findsOneWidget);

      // BCV Header Pill & tap-to-refresh
      expect(find.byKey(const Key('bcv_rate_header_pill')), findsOneWidget);
      expect(find.text('Tasa BCV: Bs. 36,50'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bcv_rate_header_pill')));
      await tester.pump();
      expect(rateNotifier.refreshCalls, 1);

      // Discounted price ($16.00 + strike-through $20.00 + ~ Bs. 584,00)
      expect(find.text('\$ 16,00'), findsOneWidget);
      expect(find.text('\$20.00'), findsOneWidget);
      expect(find.textContaining('Bs. 584,00'), findsOneWidget);

      // Variant range price ("Desde $ 25,00")
      expect(find.text('Desde \$ 25,00'), findsOneWidget);

      // Scroll down to Row 1 cards and verify their badges & meta
      final gridScrollable = find.descendant(
        of: find.byKey(const Key('catalog_bento_scroll_view')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Agotado'),
        220,
        scrollable: gridScrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('Pausado'), findsOneWidget);
      expect(find.text('Pre-orden'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Servicio · Citas'),
        220,
        scrollable: gridScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Servicio · Citas'), findsOneWidget);
    });

    testWidgets(
        'Initial loading state renders ItemsBentoGridShimmer skeleton',
        (tester) async {
      final completer = Completer<void>();
      final repo = _CatalogSpyItemRepository(
        items: _buildSampleCatalog(),
        loadCompleter: completer,
      );

      await tester.pumpWidget(_buildTestHarness(repo: repo));
      await tester.pump();

      expect(find.byType(ItemsBentoGridShimmer), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ItemsBentoGridShimmer), findsNothing);
      expect(find.byType(ItemBentoGridCard), findsWidgets);
    });
  });

  group('Unified Status Count Pills, Dedicated Category Row & Sort/Type Sheet',
      () {
    testWidgets(
        'Unified status pills show non-zero counts even when summary endpoint fails, and sort/type button opens modal sheet',
        (tester) async {
      final repo = _CatalogSpyItemRepository(
        items: _buildSampleCatalog(),
        failSummary: true,
      );

      await tester.pumpWidget(_buildTestHarness(repo: repo));
      await tester.pumpAndSettle();

      // Verify live non-zero counts in unified status pills despite summary endpoint 404
      expect(
        tester.widget<Text>(find.byKey(const Key('status_count_all'))).data,
        '5',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('status_count_published')))
            .data,
        '4',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('status_count_paused'))).data,
        '1',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('status_count_outOfStock')))
            .data,
        '1',
      );

      // Tap "Pausados" unified status pill
      await tester.tap(find.byKey(const Key('filter_status_paused')));
      await tester.pumpAndSettle();

      expect(repo.paginatedCalls.last['isActive'], false);
      expect(find.text('Prensa Francesa Clásica 600ml'), findsOneWidget);
      expect(
        find.text('Café Gourmet en Grano 500g Edición Especial'),
        findsNothing,
      );

      // Tap "Agotados" unified status pill
      await tester.ensureVisible(
        find.byKey(const Key('filter_status_out_of_stock')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter_status_out_of_stock')));
      await tester.pumpAndSettle();

      expect(repo.paginatedCalls.last['onlyOutOfStock'], true);
      expect(find.text('Termo Acero Inoxidable 1L'), findsOneWidget);

      // Open Sort & Item Type modal sheet via compact trigger button next to search
      await tester.tap(find.byKey(const Key('catalog_sort_type_button')));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar y ordenar catálogo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter_type_service')));
      await tester.pumpAndSettle();
      expect(repo.paginatedCalls.last['itemType'], ItemType.service);

      // Tap "Limpiar" reset button in dedicated category row
      await tester.ensureVisible(
        find.byKey(const Key('reset_catalog_filters_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset_catalog_filters_button')));
      await tester.pumpAndSettle();
      expect(repo.paginatedCalls.last['isActive'], isNull);
      expect(repo.paginatedCalls.last['onlyOutOfStock'], isNull);
      expect(repo.paginatedCalls.last['itemType'], isNull);
    });
  });

  group('Collaborator RBAC Matrix & In-Place Quick Actions Synchronization', () {
    testWidgets(
        'Read-only collaborator sees neither + Artículo FAB nor card ⋮ menu',
        (tester) async {
      final repo = _CatalogSpyItemRepository(items: _buildSampleCatalog());
      final readOnlyCollab = _collaboratorUser(const ['inventory:view']);

      await tester.pumpWidget(
        _buildTestHarness(repo: repo, user: readOnlyCollab),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_item_fab')), findsNothing);
      expect(
        find.byKey(const Key('item_card_more_item-discount')),
        findsNothing,
      );
    });

    testWidgets(
        'Price-only collaborator sees ONLY Ajustar Precio in quick sheet and updates card in-place without scroll reset',
        (tester) async {
      // Create 8 items so the CustomScrollView is scrollable
      final items = [
        ..._buildSampleCatalog(),
        for (int i = 1; i <= 4; i++)
          Item(
            id: 'extra-$i',
            title: 'Producto Adicional $i',
            description: 'Desc',
            basePrice: 10.0 + i,
            price: 10.0 + i,
            mainImage: '',
            images: const [],
            isFeatured: false,
            itemType: ItemType.product,
            trackInventory: true,
            stockQuantity: 5,
            requiresBooking: false,
            isActive: true,
          ),
      ];
      final repo = _CatalogSpyItemRepository(items: items);
      final priceOnlyCollab =
          _collaboratorUser(const ['inventory:change_price']);

      await tester.pumpWidget(
        _buildTestHarness(repo: repo, user: priceOnlyCollab),
      );
      await tester.pumpAndSettle();

      // No + Artículo FAB for price-only collaborator
      expect(find.byKey(const Key('create_item_fab')), findsNothing);

      // Scroll slightly and record offset
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const Key('catalog_bento_scroll_view')),
          matching: find.byType(Scrollable),
        ),
      );
      scrollable.position.jumpTo(10.0);
      await tester.pump();
      expect(scrollable.position.pixels, 10.0);

      // Open quick actions on first card
      await tester.tap(find.byKey(const Key('item_card_more_item-discount')));
      await tester.pumpAndSettle();

      // Only Ajustar Precio is shown
      expect(find.byKey(const Key('quick_action_adjust_price')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_adjust_stock')), findsNothing);
      expect(
        find.byKey(const Key('quick_action_toggle_publish')),
        findsNothing,
      );
      expect(find.byKey(const Key('quick_action_promote')), findsNothing);
      expect(find.byKey(const Key('quick_action_edit')), findsNothing);
      expect(find.byKey(const Key('quick_action_duplicate')), findsNothing);
      expect(find.byKey(const Key('quick_action_delete')), findsNothing);

      // Tap Ajustar Precio -> opens showQuickPriceSheet
      await tester.tap(find.byKey(const Key('quick_action_adjust_price')));
      await tester.pumpAndSettle();

      // Update base price to 30 and clear discount
      final textFields = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(textFields.first, '30.00');
      await tester.enterText(textFields.last, '');
      await tester.tap(find.text('Guardar Precio'));
      await tester.pumpAndSettle();

      // Card updated in-place to $ 30,00 and scroll offset preserved at 10.0!
      expect(find.text('\$ 30,00'), findsOneWidget);
      expect(scrollable.position.pixels, 10.0);
    });

    testWidgets(
        'Full owner sees + Artículo FAB and all 7 quick actions in ItemListQuickActionsSheet',
        (tester) async {
      final repo = _CatalogSpyItemRepository(items: _buildSampleCatalog());

      await tester.pumpWidget(
        _buildTestHarness(repo: repo, user: _ownerUser()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_item_fab')), findsOneWidget);

      await tester.tap(find.byKey(const Key('item_card_more_item-discount')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_action_adjust_price')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_adjust_stock')), findsOneWidget);
      expect(
        find.byKey(const Key('quick_action_toggle_publish')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('quick_action_promote')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_edit')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_duplicate')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_delete')), findsOneWidget);
    });
  });

  group('Small Viewport & Large Font Accessibility (320px @ 1.35x)', () {
    testWidgets(
        'Full ItemListScreen renders with zero RenderFlex overflow at 320px width and 1.35x textScaler',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _CatalogSpyItemRepository(items: _buildSampleCatalog());

      await tester.pumpWidget(
        _buildTestHarness(
          repo: repo,
          textScaler: const TextScaler.linear(1.35),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Scroll through the entire 2-column Bento grid to verify all rows at 320px @ 1.35x
      await tester.drag(
        find.byKey(const Key('catalog_bento_scroll_view')),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AppBar renders full "Gestionar Artículos" title and full BCV rate across 320px @ 1.35x, 360px and 800px without collision',
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

        final repo = _CatalogSpyItemRepository(items: _buildSampleCatalog());
        await tester.pumpWidget(
          _buildTestHarness(
            repo: repo,
            textScaler: TextScaler.linear(vp.scale),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'No exception at ${vp.desc}');
        expect(find.text('Gestionar Artículos'), findsOneWidget, reason: 'Title present at ${vp.desc}');
        expect(find.text('Tasa BCV: Bs. 36,50'), findsOneWidget, reason: 'BCV rate present at ${vp.desc}');

        // Verify vertical stacking: title Y < BCV rate Y
        final titlePos = tester.getTopLeft(find.text('Gestionar Artículos'));
        final ratePos = tester.getTopLeft(find.text('Tasa BCV: Bs. 36,50'));
        expect(titlePos.dy < ratePos.dy, isTrue, reason: 'Title should be above BCV pill at ${vp.desc}');
      }
    });
  });
}
