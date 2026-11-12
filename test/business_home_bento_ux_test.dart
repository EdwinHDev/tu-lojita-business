import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/dashboard/data/models/dashboard_analytics_model.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/notification.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/views/home_view.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_attention_banner.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_branch_resolver.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_breakdown_bento_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_filters_bar.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_header_banner.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_kpi_carousel.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_operational_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_quick_actions_panel.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_sales_trend_chart.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_share_progress_tile.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/repositories/item_repository.dart';
import 'widget_test.dart';

class _FakeItemRepository extends Fake implements ItemRepository {
  @override
  Future<Item> getItemById(String id) async {
    return Item(
      id: id,
      title: 'Zapatillas Urbanas Edición Especial',
      description: 'Descripción de prueba',
      price: 60.0,
      mainImage: '/item1.png',
      images: const ['/item1.png'],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 10,
      requiresBooking: false,
    );
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
  _FakeExchangeRateNotifier(this._config);

  @override
  Future<ExchangeRateConfig> build() async => _config;

  @override
  Future<void> refreshRate() async {
    state = AsyncData(_config);
  }
}

class _FakeNotificationsNotifier extends NotificationsNotifier {
  final List<AppNotification> _items;
  _FakeNotificationsNotifier(this._items);

  @override
  Future<List<AppNotification>> build() async => _items;

  @override
  Future<void> loadNotifications() async {
    state = AsyncData(_items);
  }
}

class _FakeStoresNotifier extends StoresNotifier {
  final List<Store> _stores;
  _FakeStoresNotifier(this._stores);

  @override
  StoresState build() => StoresState(
        stores: _stores,
        stats: const DashboardStats(
          salesToday: SalesStats(amount: 120.0, percentage: 10, currency: 'USD'),
          totalStores: CountStats(count: 2, increment: 0),
          totalProducts: CountStats(count: 15, increment: 2),
          totalCustomers: CountStats(count: 8, increment: 1),
        ),
      );

  @override
  Future<void> loadData() async {}
}

class _FakeDashboardAnalyticsNotifier extends DashboardAnalyticsNotifier {
  final DashboardAnalyticsState _initialState;
  _FakeDashboardAnalyticsNotifier(this._initialState);

  @override
  DashboardAnalyticsState build() => _initialState;

  @override
  Future<void> loadAnalytics({bool isRefresh = false}) async {}
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    await initializeDateFormatting('es');
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  const company = Company(
    id: 'comp-1',
    name: 'Comercial Tu Lojita',
    rif: 'J-12345678-9',
    logo: '/company-logo.png',
  );

  const ownerUser = User(
    id: 'u-1',
    email: 'owner@tulojita.com',
    firstName: 'Edwin',
    lastName: 'Morales',
    role: 'COMPANY',
    hasCompany: true,
    company: company,
    isCollaborator: false,
  );

  const restrictedCollaborator = User(
    id: 'u-2',
    email: 'collab@tulojita.com',
    firstName: 'Carlos',
    lastName: 'Operador',
    role: 'COMPANY',
    hasCompany: true,
    company: company,
    isCollaborator: true,
    collaboratorRole: 'Despachador',
    hasFullBranchAccess: false,
    allowedBranchIds: ['store-1'],
    permissions: ['orders:view'],
  );

  const store1 = Store(
    id: 'store-1',
    name: 'Tu Lojita',
    branchName: 'Centro',
    logo: '/s1.png',
    status: 'ACTIVE',
    hasMultipleBranches: true,
  );

  const store2 = Store(
    id: 'store-2',
    name: 'Tu Lojita',
    branchName: 'Norte',
    logo: '/s2.png',
    status: 'ACTIVE',
    hasMultipleBranches: true,
  );

  const enabledRate = ExchangeRateConfig(enabled: true, rate: 50.0);
  const disabledRate = ExchangeRateConfig(enabled: false, rate: 0.0);

  DashboardAnalytics sampleAnalytics({
    List<SalesChartPoint>? chartPoints,
    OperationalSummary summary = const OperationalSummary(
      totalCommissionDebt: 18.50,
      storesWithDebtCount: 1,
      pendingCommissionReportsCount: 1,
      activePromotionsCount: 2,
      pendingPromotionsCount: 1,
      topDivision: 'TIENDA_MARCA',
      topDivisionTitle: 'Tienda de Marca',
      highestPR: 420,
      maxConsecutiveSalesDays: 5,
      dailyMissionsCompletedToday: 2,
      storesInDangerZoneCount: 0,
      storesScheduledForDeletionCount: 0,
    ),
    int pendingOrders = 2,
    double totalSales = 1500.0,
  }) {
    return DashboardAnalytics(
      period: 'month',
      startDate: '2026-10-01T00:00:00Z',
      endDate: '2026-10-31T23:59:59Z',
      storeId: 'all',
      currency: 'USD',
      kpis: KpiMetrics(
        totalSales: totalSales,
        totalCollected: 1100.0,
        accountsReceivable: 400.0,
        totalOrders: 24,
        completedOrders: 20,
        pendingOrders: pendingOrders,
        averageTicket: 62.5,
        installmentRatio: const InstallmentRatio(
          installmentOrdersCount: 8,
          singlePaymentOrdersCount: 16,
          installmentPercentage: 33.3,
          singlePaymentPercentage: 66.7,
        ),
        growth: const GrowthMetrics(
          salesGrowthPercentage: 14.5,
          ordersGrowthPercentage: 8.0,
        ),
      ),
      salesChart: chartPoints ??
          List.generate(
            30,
            (i) => SalesChartPoint(
              label: '${(i + 1).toString().padLeft(2, '0')}/10',
              date: '2026-10-${(i + 1).toString().padLeft(2, '0')}',
              sales: i == 14 ? 420.0 : (i % 5 == 0 ? 110.0 : 0.0),
              ordersCount: i == 14 ? 6 : (i % 5 == 0 ? 2 : 0),
            ),
          ),
      storesPerformance: const [
        StorePerformance(
          storeId: 'store-1',
          storeName: 'Centro',
          totalSales: 950.0,
          ordersCount: 15,
          percentageOfTotal: 63.3,
        ),
        StorePerformance(
          storeId: 'store-2',
          storeName: 'Norte',
          totalSales: 550.0,
          ordersCount: 9,
          percentageOfTotal: 36.7,
        ),
      ],
      topProducts: const [
        TopProduct(
          itemId: 'item-1',
          title: 'Zapatillas Urbanas Edición Especial',
          mainImage: '/item1.png',
          unitsSold: 12,
          totalRevenue: 720.0,
        ),
      ],
      topDesiredProducts: const [
        TopDesiredProduct(
          itemId: 'item-2',
          title: 'Morral Impermeable Pro',
          mainImage: '/item2.png',
          favoritesCount: 19,
          price: 45.0,
          stockQuantity: 0,
          trackInventory: true,
        ),
      ],
      paymentMethods: const [
        PaymentMethodShare(
          method: 'PAGO_MOVIL',
          label: 'Pago Móvil',
          totalAmount: 750.0,
          percentage: 68.2,
          transactionCount: 14,
        ),
      ],
      operationalSummary: summary,
    );
  }

  Widget wrapWithViewport({
    required Widget child,
    double width = 320,
    double textScale = 1.0,
    ExchangeRateConfig rateConfig = enabledRate,
    User user = ownerUser,
    List<Store> stores = const [store1, store2],
    List<AppNotification> notifications = const [],
    DashboardAnalyticsState? analyticsState,
  }) {
    final effectiveAnalytics = analyticsState ??
        DashboardAnalyticsState(
          status: DashboardAnalyticsStatus.loaded,
          analytics: sampleAnalytics(),
        );

    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith(() => _FakeAuthNotifier(user)),
        exchangeRateProvider
            .overrideWith(() => _FakeExchangeRateNotifier(rateConfig)),
        notificationsProvider
            .overrideWith(() => _FakeNotificationsNotifier(notifications)),
        storesProvider.overrideWith(() => _FakeStoresNotifier(stores)),
        dashboardAnalyticsProvider
            .overrideWith(() => _FakeDashboardAnalyticsNotifier(effectiveAnalytics)),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Task 2.2 - DashboardAnalyticsModel.fromJson', () {
    test('parses full, partial, and legacy payloads safely', () {
      final baseJson = <String, dynamic>{
        'period': 'month',
        'startDate': '2026-10-01',
        'endDate': '2026-10-31',
        'storeId': 'all',
        'currency': 'USD',
        'kpis': <String, dynamic>{},
        'salesChart': <dynamic>[],
        'storesPerformance': <dynamic>[],
        'topProducts': <dynamic>[],
        'paymentMethods': <dynamic>[],
      };

      final full = DashboardAnalyticsModel.fromJson({
        ...baseJson,
        'topProducts': [
          {
            'itemId': 'item-1',
            'title': 'Zapatillas',
            'unitsSold': 5,
            'totalRevenue': 300,
            'storeId': 'store-2',
            'storeName': 'Sucursal Norte',
          },
        ],
        'topDesiredProducts': [
          {
            'itemId': 'item-2',
            'title': 'Morral',
            'favoritesCount': 12,
            'price': 45,
            'storeId': 'store-2',
            'storeName': 'Sucursal Norte',
          },
        ],
        'operationalSummary': {
          'totalCommissionDebt': 34.5,
          'storesWithDebtCount': 2,
          'pendingCommissionReportsCount': 1,
          'activePromotionsCount': 4,
          'pendingPromotionsCount': 2,
          'topDivision': 'TIENDA_MARCA',
          'topDivisionTitle': 'Tienda de Marca',
          'highestPR': 610,
          'maxConsecutiveSalesDays': 12,
          'dailyMissionsCompletedToday': 3,
          'storesInDangerZoneCount': 1,
          'storesScheduledForDeletionCount': 1,
          'topRankingStoreId': 'store-2',
          'topRankingStoreName': 'Sucursal Norte',
          'storeAlerts': [
            {
              'storeId': 'store-2',
              'storeName': 'Sucursal Norte',
              'pendingOrders': 3,
              'accountsReceivable': 125.5,
              'commissionDebt': 34.5,
              'pendingCommissionReportsCount': 1,
              'activePromotionsCount': 4,
              'pendingPromotionsCount': 2,
              'isScheduledForDeletion': true,
            },
          ],
        },
      });
      expect(full.topProducts.first.storeId, 'store-2');
      expect(full.topProducts.first.storeName, 'Sucursal Norte');
      expect(full.topDesiredProducts.first.storeId, 'store-2');
      expect(full.topDesiredProducts.first.storeName, 'Sucursal Norte');
      expect(full.operationalSummary.totalCommissionDebt, 34.5);
      expect(full.operationalSummary.topDivisionTitle, 'Tienda de Marca');
      expect(full.operationalSummary.highestPR, 610);
      expect(full.operationalSummary.storesScheduledForDeletionCount, 1);
      expect(full.operationalSummary.topRankingStoreId, 'store-2');
      expect(full.operationalSummary.topRankingStoreName, 'Sucursal Norte');
      expect(full.operationalSummary.storeAlerts.length, 1);
      expect(full.operationalSummary.storeAlerts.first.pendingOrders, 3);
      expect(full.operationalSummary.storeAlerts.first.accountsReceivable, 125.5);

      final partial = DashboardAnalyticsModel.fromJson({
        ...baseJson,
        'operationalSummary': {'activePromotionsCount': '3'},
      });
      expect(partial.operationalSummary.activePromotionsCount, 3);
      expect(partial.operationalSummary.totalCommissionDebt, 0.0);
      expect(partial.operationalSummary.topDivision, isNull);
      expect(partial.operationalSummary.storeAlerts, isEmpty);
      expect(partial.operationalSummary.topRankingStoreId, isNull);

      final legacy = DashboardAnalyticsModel.fromJson(baseJson);
      expect(legacy.operationalSummary.totalCommissionDebt, 0.0);
      expect(legacy.operationalSummary.maxConsecutiveSalesDays, 0);
      expect(legacy.operationalSummary.topDivisionTitle, isNull);
      expect(legacy.operationalSummary.storeAlerts, isEmpty);
      expect(legacy.operationalSummary.topRankingStoreName, isNull);
    });
  });

  group('Task 2.3 & 3.1 - resolveOriginStoreId & router ai-settings', () {
    testWidgets('returns null for 0 options, direct for 1 option, and filtered sheet with badges for 2+ options',
        (tester) async {
      String? resolvedEmpty = 'sentinel';
      String? resolvedSingle;
      String? resolvedMulti;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      resolvedEmpty = await resolveOriginStoreId(
                        context,
                        selectedStoreId: 'all',
                        options: const [],
                      );
                    },
                    child: const Text('Empty'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      resolvedSingle = await resolveOriginStoreId(
                        context,
                        selectedStoreId: 'all',
                        options: const [
                          OriginStoreOption(
                            store: store1,
                            metricBadge: '2 pedidos',
                            useAmberBadge: true,
                          ),
                        ],
                      );
                    },
                    child: const Text('Single'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      resolvedMulti = await resolveOriginStoreId(
                        context,
                        selectedStoreId: 'all',
                        options: const [
                          OriginStoreOption(
                            store: store1,
                            metricBadge: '3 pedidos',
                            useAmberBadge: true,
                          ),
                          OriginStoreOption(
                            store: store2,
                            metricBadge: '1 pedido',
                            useAmberBadge: true,
                          ),
                        ],
                      );
                    },
                    child: const Text('Multi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Empty'));
      await tester.pumpAndSettle();
      expect(resolvedEmpty, isNull);

      await tester.tap(find.text('Single'));
      await tester.pumpAndSettle();
      expect(resolvedSingle, 'store-1');

      await tester.tap(find.text('Multi'));
      await tester.pumpAndSettle();
      expect(find.text('3 pedidos'), findsOneWidget);
      expect(find.text('1 pedido'), findsOneWidget);
      expect(find.text('Sucursal Norte'), findsOneWidget);
      await tester.tap(find.text('Sucursal Norte'));
      await tester.pumpAndSettle();
      expect(resolvedMulti, 'store-2');
    });

    testWidgets('GoRouter exposes /dashboard/stores/:storeId/ai-settings',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard/stores/store-1/ai-settings',
        routes: [
          GoRoute(
            path: '/dashboard/stores/:storeId/ai-settings',
            builder: (_, state) => Text(
              'AI:${state.pathParameters['storeId']}',
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('AI:store-1'), findsOneWidget);
    });
  });

  group('Task 3.1 & 3.2 - Compact Header, Filter Pills & Attention Banner', () {
    testWidgets('renders emoji-free header, BCV pill, and hides when disabled at 320px 1.3x',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.3,
          rateConfig: enabledRate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeaderBanner(
                userName: 'Edwin',
                companyLogoUrl: '/logo.png',
                activeScopeLabel: 'Comercial Tu Lojita',
              ),
              const SizedBox(height: 12),
              HomeFiltersBar(
                selectedPeriod: 'month',
                selectedStoreId: 'all',
                customStartDate: null,
                customEndDate: null,
                stores: const [store1, store2],
                onPeriodSelected: (_) {},
                onStoreSelected: (_) {},
                onCustomRangeSelected: (_, _) {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hola, Edwin'), findsOneWidget);
      expect(find.textContaining('👋'), findsNothing);
      expect(find.textContaining('Tasa BCV: Bs. 50,00'), findsOneWidget);
      expect(find.text('Todas las sedes'), findsOneWidget);
      expect(find.text('Este Mes'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.3,
          rateConfig: disabledRate,
          child: HomeFiltersBar(
            selectedPeriod: 'month',
            selectedStoreId: 'all',
            customStartDate: null,
            customEndDate: null,
            stores: const [store1, store2],
            onPeriodSelected: (_) {},
            onStoreSelected: (_) {},
            onCustomRangeSelected: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Tasa BCV'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeAttentionBanner collapses when all counts are zero and renders when alerts exist',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          child: const HomeAttentionBanner(
            pendingOrders: 0,
            unreadDisputesCount: 0,
            summary: OperationalSummary(),
            stores: [store1],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Atención operativa'), findsNothing);

      await tester.pumpWidget(
        wrapWithViewport(
          child: HomeAttentionBanner(
            pendingOrders: 3,
            unreadDisputesCount: 1,
            summary: sampleAnalytics().operationalSummary,
            stores: const [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Atención operativa'), findsOneWidget);
      expect(find.text('3 pedidos pendientes'), findsOneWidget);
      expect(find.text('1 reclamo sin leer'), findsOneWidget);
      expect(find.textContaining('Comisión:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Task 3.3 - HomeKpiCarousel responsive 320px, 600px+, and 1.3x', () {
    testWidgets('renders 3-slide carousel with dual pricing on 320px 1.3x without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.3,
          child: HomeKpiCarousel(
            analytics: sampleAnalytics(totalSales: 45000.0),
            stores: const [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VENTAS TOTALES'), findsOneWidget);
      expect(find.text('\$ 45.000,00'), findsOneWidget);
      expect(find.text('~ Bs. 2.250.000,00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('CAJA Y CARTERA'), findsOneWidget);
      expect(find.text('Recaudado en Bancos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expands to multi-column Bento grid on >= 600px viewports',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          width: 720,
          child: HomeKpiCarousel(
            analytics: sampleAnalytics(),
            stores: const [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing);
      expect(find.text('VENTAS TOTALES'), findsOneWidget);
      expect(find.text('CAJA Y CARTERA'), findsOneWidget);
      expect(find.text('NOVEDADES Y SALUD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Task 4.1, 4.2, 4.3 - Shortcuts, Hybrid Chart & Breakdown Bento', () {
    testWidgets('HomeQuickActionsPanel renders strictly Accesos de Empresa across owner and collaborator roles',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          user: ownerUser,
          child: const HomeQuickActionsPanel(
            stores: [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accesos de Empresa'), findsOneWidget);
      expect(find.text('Tiendas'), findsOneWidget);
      expect(find.text('Nueva Sede'), findsOneWidget);
      expect(find.text('Equipo'), findsOneWidget);

      // Must never render store-scoped operational shortcuts
      expect(find.text('Pedidos'), findsNothing);
      expect(find.text('Promocionar'), findsNothing);
      expect(find.text('Fotos IA'), findsNothing);
      expect(find.text('Comisiones'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Mi Empresa'),
        120,
        scrollable: find.descendant(
          of: find.byType(HomeQuickActionsPanel),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Actividad'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);
      expect(find.text('Mi Empresa'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Even with 1 store selected, store-scoped shortcuts must remain absent
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          user: ownerUser,
          child: const HomeQuickActionsPanel(
            stores: [store1],
            selectedStoreId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accesos de Empresa'), findsOneWidget);
      expect(find.text('Pedidos'), findsNothing);
      expect(find.text('Promocionar'), findsNothing);
      expect(find.text('Fotos IA'), findsNothing);
      expect(find.text('Comisiones'), findsNothing);

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          user: restrictedCollaborator,
          child: const HomeQuickActionsPanel(
            stores: [store1],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiendas'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);
      expect(find.text('Pedidos'), findsNothing);
      expect(find.text('Comisiones'), findsNothing);
      expect(find.text('Nueva Sede'), findsNothing);
      expect(find.text('Actividad'), findsNothing);
      expect(find.text('Mi Empresa'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeSalesTrendChart supports empty, sparse Area, and scrollable Bars mode',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          child: const HomeSalesTrendChart(salesChart: [], period: 'month'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin datos de ventas en este período'), findsOneWidget);

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.35,
          child: HomeSalesTrendChart(
            salesChart: sampleAnalytics().salesChart,
            period: 'month',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('15/10'), findsWidgets);
      expect(find.text('\$ 420,00'), findsOneWidget);
      expect(find.text('~ Bs. 21.000,00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Barras'));
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.ensureVisible(find.text('01/10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('01/10'));
      await tester.pumpAndSettle();
      expect(find.text('\$ 110,00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeBreakdownBentoCard switches segments and hides Sedes on single branch',
        (tester) async {
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          child: HomeBreakdownBentoCard(
            analytics: sampleAnalytics(),
            stores: const [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zapatillas Urbanas Edición Especial'), findsOneWidget);
      expect(find.text('Sedes'), findsOneWidget);

      await tester.tap(find.text('Deseados'));
      await tester.pumpAndSettle();
      expect(find.text('Morral Impermeable Pro'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);

      await tester.ensureVisible(find.text('Métodos'));
      await tester.tap(find.text('Métodos'));
      await tester.pumpAndSettle();
      expect(find.text('Pago Móvil'), findsOneWidget);

      await tester.ensureVisible(find.text('Sedes'));
      await tester.tap(find.text('Sedes'));
      await tester.pumpAndSettle();
      expect(find.text('Centro'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          child: HomeBreakdownBentoCard(
            analytics: sampleAnalytics(),
            stores: const [store1, store2],
            selectedStoreId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sedes'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Task 5.1 - Collaborator Mode, Shimmer & DashboardShell AppBar', () {
    testWidgets('HomeView renders operational Bento without financials for restricted collaborator',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider
                .overrideWith(() => _FakeAuthNotifier(restrictedCollaborator)),
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            notificationsProvider
                .overrideWith(() => _FakeNotificationsNotifier(const [])),
            storesProvider
                .overrideWith(() => _FakeStoresNotifier(const [store1, store2])),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 340, height: 700, child: HomeView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hola, Carlos'), findsOneWidget);
      expect(find.text('Panel Operativo de Sucursales'), findsOneWidget);
      expect(
        find.text('1 sucursal(es) autorizada(s) para operar'),
        findsOneWidget,
      );
      expect(find.text('VENTAS TOTALES'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeView renders ShimmerWidget skeleton while analytics are loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeAuthNotifier(ownerUser)),
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            notificationsProvider
                .overrideWith(() => _FakeNotificationsNotifier(const [])),
            storesProvider
                .overrideWith(() => _FakeStoresNotifier(const [store1])),
            dashboardAnalyticsProvider.overrideWith(
              () => _FakeDashboardAnalyticsNotifier(
                const DashboardAnalyticsState(
                  status: DashboardAnalyticsStatus.loading,
                  analytics: null,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: SizedBox(width: 340, height: 700, child: HomeView()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ShimmerWidget), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DashboardScreen hides legacy Dashboard AppBar on both Inicio and Tiendas tabs',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeAuthNotifier(ownerUser)),
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            notificationsProvider
                .overrideWith(() => _FakeNotificationsNotifier(const [])),
            storesProvider
                .overrideWith(() => _FakeStoresNotifier(const [store1])),
            dashboardAnalyticsProvider.overrideWith(
              () => _FakeDashboardAnalyticsNotifier(
                DashboardAnalyticsState(
                  status: DashboardAnalyticsStatus.loaded,
                  analytics: sampleAnalytics(),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tab 0 (Inicio): no generic "Dashboard" AppBar
      expect(find.widgetWithText(AppBar, 'Dashboard'), findsNothing);

      // Switch to Tab 1 (Tiendas): still no legacy "Dashboard" AppBar, integrated Bento header shows instead
      await tester.tap(find.text('Tiendas').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.widgetWithText(AppBar, 'Dashboard'), findsNothing);
      expect(find.text('Mi Tienda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Designer Round-1 Fixes Regression Coverage', () {
    testWidgets(
        'HomeKpiCarousel renders 0% donut when flow is zero and Slide 3 fits without internal scroll at 320px 1.35x',
        (tester) async {
      final zeroFlow = DashboardAnalytics(
        period: 'month',
        startDate: '2026-10-01T00:00:00Z',
        endDate: '2026-10-31T23:59:59Z',
        storeId: 'all',
        currency: 'USD',
        kpis: const KpiMetrics(
          totalSales: 0,
          totalCollected: 0,
          accountsReceivable: 0,
          totalOrders: 0,
          completedOrders: 0,
          pendingOrders: 0,
          averageTicket: 0,
          installmentRatio: InstallmentRatio(
            installmentOrdersCount: 0,
            singlePaymentOrdersCount: 0,
            installmentPercentage: 0,
            singlePaymentPercentage: 0,
          ),
          growth: GrowthMetrics(
            salesGrowthPercentage: 0,
            ordersGrowthPercentage: 0,
          ),
        ),
        salesChart: const [],
        storesPerformance: const [],
        topProducts: const [],
        topDesiredProducts: const [],
        paymentMethods: const [],
        operationalSummary: sampleAnalytics().operationalSummary,
      );

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.35,
          child: HomeKpiCarousel(
            analytics: zeroFlow,
            stores: const [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe to Slide 2 (CAJA Y CARTERA)
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('CAJA Y CARTERA'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Sin cobros'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Swipe to Slide 3 (NOVEDADES Y SALUD)
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('NOVEDADES Y SALUD'), findsOneWidget);
      expect(find.text('Comisiones'), findsOneWidget);
      expect(find.text('Vitrina'), findsOneWidget);
      expect(find.text('Tienda de Marca'), findsOneWidget);

      final slideScrollViews = tester.stateList<ScrollableState>(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        ),
      );
      expect(slideScrollViews, isNotEmpty);
      for (final state in slideScrollViews) {
        expect(state.position.maxScrollExtent, 0.0);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'HomeBreakdownBentoCard navigates directly using product storeId without prompting multi-branch selector',
        (tester) async {
      String? pushedLocation;
      final analyticsWithStoreId = DashboardAnalytics(
        period: 'month',
        startDate: '2026-10-01T00:00:00Z',
        endDate: '2026-10-31T23:59:59Z',
        storeId: 'all',
        currency: 'USD',
        kpis: sampleAnalytics().kpis,
        salesChart: const [],
        storesPerformance: sampleAnalytics().storesPerformance,
        topProducts: const [
          TopProduct(
            itemId: 'item-1',
            title: 'Zapatillas Urbanas',
            mainImage: '/item1.png',
            unitsSold: 12,
            totalRevenue: 720.0,
            storeId: 'store-2',
            storeName: 'Norte',
          ),
        ],
        topDesiredProducts: const [
          TopDesiredProduct(
            itemId: 'item-2',
            title: 'Morral Pro',
            mainImage: '/item2.png',
            favoritesCount: 19,
            price: 45.0,
            stockQuantity: 4,
            trackInventory: true,
            storeId: 'store-2',
            storeName: 'Norte',
          ),
        ],
        paymentMethods: const [],
        operationalSummary: sampleAnalytics().operationalSummary,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: HomeBreakdownBentoCard(
                  analytics: analyticsWithStoreId,
                  stores: const [store1, store2],
                  selectedStoreId: 'all',
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/items/detail',
            builder: (_, state) {
              pushedLocation = state.uri.toString();
              return Text('DETAIL:${state.pathParameters['storeId']}');
            },
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/items',
            builder: (_, state) {
              pushedLocation = state.uri.toString();
              return Text('LIST:${state.pathParameters['storeId']}');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            itemRepositoryProvider.overrideWithValue(_FakeItemRepository()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zapatillas Urbanas'));
      await tester.pumpAndSettle();

      expect(find.text('Abrir artículo'), findsNothing);
      expect(pushedLocation, '/dashboard/stores/store-2/items/detail');
      expect(find.text('DETAIL:store-2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'HomeAttentionBanner & HomeOperationalCard gate pills strictly by collaborator permissions',
        (tester) async {
      const financialOnlyCollab = User(
        id: 'u-fin',
        email: 'fin@tulojita.com',
        firstName: 'Ana',
        lastName: 'Contadora',
        role: 'COMPANY',
        hasCompany: true,
        company: company,
        isCollaborator: true,
        hasFullBranchAccess: true,
        permissions: ['metrics:view_financial'],
      );

      final scheduledStore = Store(
        id: 'store-sched',
        name: 'Tu Lojita',
        branchName: 'Cierre',
        logo: '/s-sched.png',
        status: 'ACTIVE',
        deletionScheduledAt: DateTime(2099, 12, 1),
      );

      // Financial-only collaborator with zero financial debt must NOT see
      // pendingOrders, disputes, or scheduled deletion alerts.
      await tester.pumpWidget(
        wrapWithViewport(
          user: financialOnlyCollab,
          child: HomeAttentionBanner(
            user: financialOnlyCollab,
            pendingOrders: 4,
            unreadDisputesCount: 2,
            summary: const OperationalSummary(storesScheduledForDeletionCount: 1),
            stores: [store1, scheduledStore],
            selectedStoreId: 'all',
            canViewFinancials: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atención operativa'), findsNothing);
      expect(find.text('4 pedidos pendientes'), findsNothing);
      expect(find.text('2 reclamos sin leer'), findsNothing);
      expect(find.text('1 sede por eliminar'), findsNothing);

      // Restricted orders-only collaborator in HomeOperationalCard must NOT render
      // empty Amber alert strip when disputes & branch deletion are hidden.
      await tester.pumpWidget(
        wrapWithViewport(
          user: restrictedCollaborator,
          child: HomeOperationalCard(
            user: restrictedCollaborator,
            stores: [store1, scheduledStore],
            unreadDisputesCount: 3,
            onViewStores: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Panel Operativo de Sucursales'), findsOneWidget);
      expect(find.text('3 reclamos sin leer'), findsNothing);
      expect(find.text('1 sede por eliminar'), findsNothing);
      expect(tester.takeException(), isNull);

      // Disputes-only collaborator taps dispute pill -> navigates directly to /dashboard/notifications.
      const disputesOnlyCollab = User(
        id: 'u-disp',
        email: 'disp@tulojita.com',
        firstName: 'Luis',
        lastName: 'Soporte',
        role: 'COMPANY',
        hasCompany: true,
        company: company,
        isCollaborator: true,
        hasFullBranchAccess: true,
        permissions: ['disputes:view'],
      );

      String? disputeNavTarget;
      final disputeRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: HomeAttentionBanner(
                user: disputesOnlyCollab,
                pendingOrders: 5,
                unreadDisputesCount: 2,
                summary: OperationalSummary(),
                stores: [store1, store2],
                selectedStoreId: 'all',
                canViewFinancials: false,
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/notifications',
            builder: (_, state) {
              disputeNavTarget = state.uri.toString();
              return const Text('NOTIFS');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: disputeRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 pedidos pendientes'), findsNothing);
      expect(find.text('2 reclamos sin leer'), findsOneWidget);

      await tester.tap(find.text('2 reclamos sin leer'));
      await tester.pumpAndSettle();
      expect(disputeNavTarget, '/dashboard/notifications');
      expect(find.text('NOTIFS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'HomeHeaderBanner (99+ badge, 44x44 touch) & HomeShareProgressTile fit cleanly at 320px 1.35x',
        (tester) async {
      final manyUnread = List.generate(
        120,
        (i) => AppNotification(
          id: 'n-$i',
          title: 'Pedido #$i',
          body: 'Nuevo pedido',
          type: 'ORDER_NEW',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.35,
          notifications: manyUnread,
          child: Column(
            children: const [
              HomeHeaderBanner(
                userName: 'Edwin Morales',
                companyLogoUrl: '/logo.png',
                activeScopeLabel: 'Comercial Tu Lojita S.A.',
              ),
              SizedBox(height: 16),
              HomeShareProgressTile(
                icon: HugeIcons.strokeRoundedStore01,
                title: 'Sucursal Metropolitana Principal Caracas',
                amountInUsd: 12500.50,
                percentage: 68.4,
                summaryLabel: '142 pedidos · 68.4% del total mensual',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
      final inkWellSize = tester.getSize(
        find.ancestor(
          of: find.byType(Badge),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWellSize.width, greaterThanOrEqualTo(44.0));
      expect(inkWellSize.height, greaterThanOrEqualTo(44.0));
      expect(find.text('142 pedidos · 68.4% del total mensual'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('fix-home-multistore-navigation Regression Coverage', () {
    const store3Clean = Store(
      id: 'store-3',
      name: 'Tu Lojita',
      branchName: 'Este',
      logo: '/s3.png',
      status: 'ACTIVE',
      hasMultipleBranches: true,
    );

    testWidgets(
        'HomeAttentionBanner routes directly on 1-store origin, filters multi-store origin sheet, and sends multi-store disputes to /dashboard/notifications',
        (tester) async {
      final pushedPaths = <String>[];
      const singleOriginSummary = OperationalSummary(
        totalCommissionDebt: 25.0,
        storesWithDebtCount: 1,
        storeAlerts: [
          StoreOperationalAlert(
            storeId: 'store-1',
            storeName: 'Tu Lojita (Centro)',
            pendingOrders: 0,
          ),
          StoreOperationalAlert(
            storeId: 'store-2',
            storeName: 'Tu Lojita (Norte)',
            pendingOrders: 4,
            commissionDebt: 25.0,
          ),
        ],
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: Column(
                children: [
                  HomeAttentionBanner(
                    user: ownerUser,
                    pendingOrders: 4,
                    unreadDisputesCount: 2,
                    summary: singleOriginSummary,
                    stores: [store1, store2, store3Clean],
                    selectedStoreId: 'all',
                    canViewFinancials: true,
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/orders',
            builder: (_, state) {
              pushedPaths.add(state.uri.toString());
              return Text('ORDERS:${state.pathParameters['storeId']}');
            },
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/debts',
            builder: (_, state) {
              pushedPaths.add(state.uri.toString());
              return Text('DEBTS:${state.pathParameters['storeId']}');
            },
          ),
          GoRoute(
            path: '/dashboard/notifications',
            builder: (_, state) {
              pushedPaths.add(state.uri.toString());
              return const Text('GLOBAL_ALERTS');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Single originating store is named directly on the pill (with dual USD + Bs pricing)
      expect(find.text('4 pedidos · Norte'), findsOneWidget);
      expect(
        find.text('Comisión: \$ 25,00 (~ Bs. 1.250,00) · Norte'),
        findsOneWidget,
      );
      expect(find.text('2 reclamos sin leer'), findsOneWidget);

      // Tap pending orders -> goes directly to store-2 without modal
      await tester.tap(find.text('4 pedidos · Norte'));
      await tester.pumpAndSettle();
      expect(pushedPaths.last, '/dashboard/stores/store-2/orders');

      // Pop back and tap multi-branch unread disputes -> goes directly to /dashboard/notifications
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 reclamos sin leer'));
      await tester.pumpAndSettle();
      expect(pushedPaths.last, '/dashboard/notifications');

      // Now test 2+ affected branches out of 3 stores -> excludes store-3Clean
      const multiOriginSummary = OperationalSummary(
        totalCommissionDebt: 30.0,
        storesWithDebtCount: 2,
        storeAlerts: [
          StoreOperationalAlert(
            storeId: 'store-1',
            storeName: 'Tu Lojita (Centro)',
            pendingOrders: 2,
          ),
          StoreOperationalAlert(
            storeId: 'store-2',
            storeName: 'Tu Lojita (Norte)',
            pendingOrders: 1,
          ),
          StoreOperationalAlert(
            storeId: 'store-3',
            storeName: 'Tu Lojita (Este)',
            pendingOrders: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        wrapWithViewport(
          user: ownerUser,
          stores: const [store1, store2, store3Clean],
          child: const HomeAttentionBanner(
            user: ownerUser,
            pendingOrders: 3,
            unreadDisputesCount: 0,
            summary: multiOriginSummary,
            stores: [store1, store2, store3Clean],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 pedidos (2 sedes)'), findsOneWidget);
      await tester.tap(find.text('3 pedidos (2 sedes)'));
      await tester.pumpAndSettle();

      expect(find.text('2 pedidos'), findsOneWidget);
      expect(find.text('1 pedido'), findsOneWidget);
      expect(find.text('Sucursal Este'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'HomeKpiCarousel switches to Tiendas without blind modal on 0 pending, filters Slide 2 receivables, and routes Slide 3 ranking to topRankingStoreId',
        (tester) async {
      final pushed = <String>[];
      late ProviderContainer container;

      final kpiAnalytics = DashboardAnalytics(
        period: 'month',
        startDate: '2026-10-01T00:00:00Z',
        endDate: '2026-10-31T23:59:59Z',
        storeId: 'all',
        currency: 'USD',
        kpis: const KpiMetrics(
          totalSales: 1500.0,
          totalCollected: 1100.0,
          accountsReceivable: 200.0,
          totalOrders: 10,
          completedOrders: 10,
          pendingOrders: 0,
          averageTicket: 150.0,
          installmentRatio: InstallmentRatio(
            installmentOrdersCount: 4,
            singlePaymentOrdersCount: 6,
            installmentPercentage: 40.0,
            singlePaymentPercentage: 60.0,
          ),
          growth: GrowthMetrics(
            salesGrowthPercentage: 10.0,
            ordersGrowthPercentage: 5.0,
          ),
        ),
        salesChart: const [],
        storesPerformance: const [],
        topProducts: const [],
        topDesiredProducts: const [],
        paymentMethods: const [],
        operationalSummary: const OperationalSummary(
          totalCommissionDebt: 18.0,
          storesWithDebtCount: 1,
          topDivision: 'TIENDA_MARCA',
          topDivisionTitle: 'Tienda de Marca',
          highestPR: 520,
          maxConsecutiveSalesDays: 8,
          dailyMissionsCompletedToday: 2,
          topRankingStoreId: 'store-2',
          topRankingStoreName: 'Tu Lojita (Norte)',
          storeAlerts: [
            StoreOperationalAlert(
              storeId: 'store-1',
              storeName: 'Tu Lojita (Centro)',
              accountsReceivable: 120.0,
            ),
            StoreOperationalAlert(
              storeId: 'store-2',
              storeName: 'Tu Lojita (Norte)',
              accountsReceivable: 80.0,
              commissionDebt: 18.0,
            ),
            StoreOperationalAlert(
              storeId: 'store-3',
              storeName: 'Tu Lojita (Este)',
              accountsReceivable: 0.0,
            ),
          ],
        ),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    child: HomeKpiCarousel(
                      analytics: kpiAnalytics,
                      stores: const [store1, store2, store3Clean],
                      selectedStoreId: 'all',
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/ranking',
            builder: (_, state) {
              pushed.add(state.uri.toString());
              return Text('RANK:${state.pathParameters['storeId']}');
            },
          ),
        ],
      );

      container = ProviderContainer(
        overrides: [
          exchangeRateProvider
              .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1: tap Pedidos when pendingOrders == 0 in consolidated all -> opens Tiendas tab (index 1)
      await tester.tap(find.text('Pedidos'));
      await tester.pumpAndSettle();
      expect(container.read(dashboardIndexProvider), 1);

      // Slide 2: receivables sheet shows ONLY store-1 & store-2, never store-3Clean
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver cuotas ›'));
      await tester.pumpAndSettle();
      expect(find.text('Sucursal Centro'), findsOneWidget);
      expect(find.text('Sucursal Norte'), findsOneWidget);
      expect(find.text('Sucursal Este'), findsNothing);

      // Close modal sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Slide 3: shows PR metrics before topRankingStoreName and routes directly to store-2/ranking
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tienda de Marca'), findsOneWidget);
      final rankingFinder = find.textContaining('520 PR · 2 misiones hoy · Tu Lojita (Norte)');
      expect(rankingFinder, findsOneWidget);

      await tester.tap(find.text('Tienda de Marca'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/dashboard/stores/store-2/ranking');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'resolveOriginStoreId preserves branchLabel alongside option.subtitle and Slide 3 prioritizes PR metrics at 320px 1.35x',
        (tester) async {
      const commSummary = OperationalSummary(
        totalCommissionDebt: 60.0,
        storesWithDebtCount: 2,
        pendingCommissionReportsCount: 2,
        topDivision: 'TIENDA_MARCA',
        topDivisionTitle: 'Tienda de Marca',
        highestPR: 520,
        dailyMissionsCompletedToday: 2,
        topRankingStoreId: 'store-2',
        topRankingStoreName: 'Comercializadora Tu Lojita Metropolitana Principal',
        storeAlerts: [
          StoreOperationalAlert(
            storeId: 'store-1',
            storeName: 'Tu Lojita (Centro)',
            commissionDebt: 35.0,
            pendingCommissionReportsCount: 1,
          ),
          StoreOperationalAlert(
            storeId: 'store-2',
            storeName: 'Tu Lojita (Norte)',
            commissionDebt: 25.0,
            pendingCommissionReportsCount: 1,
          ),
        ],
      );

      final commissionOptions = buildCommissionOriginOptions(
        summary: commSummary,
        stores: const [store1, store2],
        exchangeConfig: enabledRate,
      );

      String? selectedCommStore;
      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.35,
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    selectedCommStore = await resolveOriginStoreId(
                      context,
                      selectedStoreId: 'all',
                      options: commissionOptions,
                      title: 'Comisiones por sede',
                    );
                  },
                  child: const Text('OpenCommSheet'),
                ),
                HomeKpiCarousel(
                  analytics: sampleAnalytics(summary: commSummary),
                  stores: const [store1, store2],
                  selectedStoreId: 'all',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open commission sheet -> both homonymous stores keep Sucursal Centro / Norte alongside report subtitle
      await tester.tap(find.text('OpenCommSheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sucursal Centro · 1 pago(s) en revisión'), findsOneWidget);
      expect(find.text('Sucursal Norte · 1 pago(s) en revisión'), findsOneWidget);
      await tester.tap(find.text('Sucursal Norte · 1 pago(s) en revisión'));
      await tester.pumpAndSettle();
      expect(selectedCommStore, 'store-2');

      // Swipe to Slide 3 at 320px + 1.35x with long storeName -> PR metrics stay first & intact
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      final rankingTextWidget = tester.widget<Text>(
        find.textContaining('520 PR'),
      );
      expect(
        rankingTextWidget.data,
        startsWith('520 PR · 2 misiones hoy · Comercializadora'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'HomeBreakdownBentoCard shows origin storeName on Vendidos/Deseados and pending badge on Sedes at 320px 1.35x',
        (tester) async {
      final breakdownAnalytics = DashboardAnalytics(
        period: 'month',
        startDate: '2026-10-01T00:00:00Z',
        endDate: '2026-10-31T23:59:59Z',
        storeId: 'all',
        currency: 'USD',
        kpis: sampleAnalytics().kpis,
        salesChart: const [],
        storesPerformance: sampleAnalytics().storesPerformance,
        topProducts: const [
          TopProduct(
            itemId: 'item-1',
            title: 'Zapatillas Urbanas Edición Especial',
            mainImage: '/item1.png',
            unitsSold: 12,
            totalRevenue: 720.0,
            storeId: 'store-2',
            storeName: 'Tu Lojita (Norte)',
          ),
        ],
        topDesiredProducts: const [
          TopDesiredProduct(
            itemId: 'item-2',
            title: 'Morral Impermeable Pro',
            mainImage: '/item2.png',
            favoritesCount: 19,
            price: 45.0,
            stockQuantity: 0,
            trackInventory: true,
            storeId: 'store-2',
            storeName: 'Tu Lojita (Norte)',
          ),
        ],
        paymentMethods: const [],
        operationalSummary: const OperationalSummary(
          storeAlerts: [
            StoreOperationalAlert(
              storeId: 'store-1',
              storeName: 'Tu Lojita (Centro)',
              pendingOrders: 3,
            ),
            StoreOperationalAlert(
              storeId: 'store-2',
              storeName: 'Tu Lojita (Norte)',
              pendingOrders: 0,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        wrapWithViewport(
          width: 320,
          textScale: 1.35,
          child: HomeBreakdownBentoCard(
            analytics: breakdownAnalytics,
            stores: const [store1, store2],
            selectedStoreId: 'all',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12 unid. · Tu Lojita (Norte)'), findsOneWidget);

      await tester.tap(find.text('Deseados'));
      await tester.pumpAndSettle();
      expect(find.text('Tu Lojita (Norte)'), findsOneWidget);

      await tester.ensureVisible(find.text('Sedes'));
      await tester.tap(find.text('Sedes'));
      await tester.pumpAndSettle();
      expect(find.text('3 pend.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'HomeOperationalCard routes multi-branch disputes to /dashboard/notifications, single-branch to /orders, and filters scheduled deletion sheet',
        (tester) async {
      final pushed = <String>[];
      const collabMultiBranch = User(
        id: 'u-op-multi',
        email: 'opm@tulojita.com',
        firstName: 'Mario',
        lastName: 'Ríos',
        role: 'COMPANY',
        hasCompany: true,
        company: company,
        isCollaborator: true,
        hasFullBranchAccess: true,
        permissions: ['disputes:view', 'orders:view', 'branches:manage'],
      );
      const collabSingleBranch = User(
        id: 'u-op-single',
        email: 'ops@tulojita.com',
        firstName: 'Sara',
        lastName: 'Luz',
        role: 'COMPANY',
        hasCompany: true,
        company: company,
        isCollaborator: true,
        hasFullBranchAccess: false,
        allowedBranchIds: ['store-1'],
        permissions: ['disputes:view', 'orders:view'],
      );

      final scheduledStore2 = Store(
        id: 'store-del-2',
        name: 'Tu Lojita',
        branchName: 'Oeste',
        logo: '/sdel2.png',
        status: 'ACTIVE',
        hasMultipleBranches: true,
        deletionScheduledAt: DateTime(2099, 12, 5),
      );
      final scheduledStore3 = Store(
        id: 'store-del-3',
        name: 'Tu Lojita',
        branchName: 'Sur',
        logo: '/sdel3.png',
        status: 'ACTIVE',
        hasMultipleBranches: true,
        deletionScheduledAt: DateTime(2099, 12, 8),
      );

      final multiRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: HomeOperationalCard(
                  user: collabMultiBranch,
                  stores: [store1, scheduledStore2, scheduledStore3],
                  unreadDisputesCount: 2,
                  onViewStores: () {},
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/notifications',
            builder: (_, state) {
              pushed.add(state.uri.toString());
              return const Text('OP_NOTIFS');
            },
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId',
            builder: (_, state) {
              pushed.add(state.uri.toString());
              return Text('STORE:${state.pathParameters['storeId']}');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: multiRouter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('2 reclamos sin leer'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/dashboard/notifications');

      multiRouter.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('2 sedes por eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Sucursal Oeste'), findsOneWidget);
      expect(find.text('Sucursal Sur'), findsOneWidget);
      expect(find.text('Sucursal Centro'), findsNothing);
      await tester.tap(find.text('Sucursal Oeste'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/dashboard/stores/store-del-2');

      // Now single-branch authorized collaborator goes direct to /orders
      final singleRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: HomeOperationalCard(
                user: collabSingleBranch,
                stores: const [store1, store2],
                unreadDisputesCount: 1,
                onViewStores: () {},
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/orders',
            builder: (_, state) {
              pushed.add(state.uri.toString());
              return Text('SINGLE_ORD:${state.pathParameters['storeId']}');
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: singleRouter,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 reclamo sin leer'));
      await tester.pumpAndSettle();
      expect(pushed.last, '/dashboard/stores/store-1/orders');
      expect(tester.takeException(), isNull);
    });
  });
}
