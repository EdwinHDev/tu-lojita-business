import 'dart:io';
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
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/dashboard/data/models/store_dashboard_model.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/notification.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_details_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_details_activity_section.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_details_identity_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_details_management_sheet.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_details_metrics_bento.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_readiness_checklist_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_urgent_alerts_strip.dart';
import 'package:tu_lojita_business/features/ranking/domain/entities/ranking_models.dart';
import 'package:tu_lojita_business/features/ranking/presentation/providers/ranking_providers.dart';
import 'package:tu_lojita_business/features/ranking/presentation/widgets/store_rank_header_card.dart';
import 'package:tu_lojita_business/features/store_ai/presentation/providers/store_ai_providers.dart';
import 'widget_test.dart';

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

class _FakeStoreDetailsNotifier extends StoreDetailsNotifier {
  final StoreDetailsData _data;
  _FakeStoreDetailsNotifier(this._data);

  @override
  StoreDetailsState build() => StoreDetailsState(
        storeData: {if (_data.store != null) _data.store!.id: _data},
        isLoading: false,
      );

  @override
  Future<void> loadData(String storeId, {bool force = false}) async {}

  @override
  Future<void> refresh(String storeId) async {}
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
    id: 'owner-1',
    email: 'owner@tulojita.com',
    firstName: 'Edwin',
    lastName: 'Morales',
    role: 'COMPANY',
    isCollaborator: false,
    company: company,
  );

  const limitedOrderCollab = User(
    id: 'collab-orders',
    email: 'orders@tulojita.com',
    firstName: 'María',
    lastName: 'Colab',
    role: 'COLLABORATOR',
    isCollaborator: true,
    company: company,
    allowedBranchIds: ['store-1'],
    permissions: ['branches:view', 'orders:view'],
    aiAllowedStoreIds: [],
  );

  const sampleStore = Store(
    id: 'store-1',
    name: 'Tu Lojita',
    branchName: 'Centro',
    address: 'Av. Bolívar, Centro',
    phone: '+58 412 5550101',
    hasMultipleBranches: true,
    logo: '',
    status: 'ACTIVE',
    allowPartialPayments: true,
    maxInstallments: 4,
    productsCount: 18,
    pendingOrdersCount: 3,
    commissionDebt: 32.5,
    pendingCommissionReportsCount: 2,
    aiEnabled: true,
  );

  const sampleDashboard = StoreDashboard(
    stats: StoreStats(
      salesToday: 250.0,
      salesTodayPercentage: 25.0,
      currency: 'USD',
      totalItems: 18,
      totalCategories: 5,
      totalCustomers: 42,
      pendingOrdersCount: 3,
      openDisputesCount: 1,
      commissionDebt: 32.5,
      pendingCommissionReportsCount: 2,
      activeStrikesCount: 1,
      pendingMediationRequestsCount: 2,
      paymentMethodsCount: 3,
      aiEnabled: true,
    ),
    recentSales: [
      StoreRecentSale(
        id: 'ord-r1',
        storeName: 'Tu Lojita',
        amount: 75.0,
        currency: 'USD',
        time: '2:15 PM',
        orderId: 'ord-r1',
        status: 'FULLY_PAID',
        itemTitle: 'Zapatillas Urbanas',
      ),
    ],
    pendingOrders: [
      StorePendingOrder(
        id: 'ord-p1',
        orderId: 'ord-p1',
        customerName: 'Carlos Gómez',
        amount: 45.0,
        currency: 'USD',
        time: '3:10 PM',
        status: 'PENDING',
        itemTitle: 'Camisa Oxford',
      ),
    ],
  );

  final sampleRanking = StoreRankingData(
    storeId: 'store-1',
    division: 'GOLD',
    divisionTitle: 'Oro I',
    currentLp: 420,
    currentPR: 1420,
    lifetimeLp: 2100,
    ordersCompletedCount: 30,
    inCalibration: false,
    flaggedForReview: false,
    position: 4,
    consecutiveSalesDays: 6,
    showcase: const [],
  );

  const dualExchangeRate = ExchangeRateConfig(
    rate: 42.5,
    currency: 'VES',
    symbol: 'Bs.',
    enabled: true,
  );

  Widget wrapViewport({
    required double width,
    double textScale = 1.0,
    required User user,
    required StoreDetailsData detailsData,
    List<AppNotification> notifications = const [],
    bool aiGlobalEnabled = true,
  }) {
    final router = GoRouter(
      initialLocation: '/stores/store-1',
      routes: [
        GoRoute(
          path: '/stores/:storeId',
          builder: (context, state) =>
              StoreDetailsScreen(storeId: state.pathParameters['storeId']!),
        ),
        GoRoute(
          path: '/dashboard/stores/:storeId/:section',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('dest:${state.pathParameters['section']}'),
            ),
          ),
        ),
        GoRoute(
          path: '/dashboard/stores/:storeId/categories/new',
          builder: (context, state) =>
              const Scaffold(body: Text('dest:categories-new')),
        ),
        GoRoute(
          path: '/dashboard/stores/:storeId/items/new',
          builder: (context, state) =>
              const Scaffold(body: Text('dest:items-new')),
        ),
        GoRoute(
          path: '/dashboard/orders/:orderId',
          builder: (context, state) => Scaffold(
            body: Text('order:${state.pathParameters['orderId']}'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _FakeAuthNotifier(user)),
        exchangeRateProvider
            .overrideWith(() => _FakeExchangeRateNotifier(dualExchangeRate)),
        notificationsProvider
            .overrideWith(() => _FakeNotificationsNotifier(notifications)),
        storeDetailsProvider
            .overrideWith(() => _FakeStoreDetailsNotifier(detailsData)),
        storeRankingProvider('store-1').overrideWith((_) async => sampleRanking),
        dailyMissionsProvider('store-1').overrideWith((_) async => const []),
        platformAiGlobalEnabledProvider.overrideWith((_) async => aiGlobalEnabled),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: TuLojitaBrandColors.indigo600),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              size: Size(width, 760),
              textScaler: TextScaler.linear(textScale),
            ),
            child: SizedBox(width: width, child: child),
          );
        },
      ),
    );
  }

  group('StoreDashboardModel JSON parsing', () {
    test('parses complete backend DTO payload including negative percentage and pendingOrders', () {
      final model = StoreDashboardModel.fromJson({
        'stats': {
          'salesToday': {
            'amount': 312.5,
            'percentage': -12.5,
            'currency': 'USD',
          },
          'totalItems': 15,
          'totalCategories': 4,
          'totalCustomers': 28,
          'pendingOrdersCount': 5,
          'openDisputesCount': 2,
          'commissionDebt': 19.75,
          'pendingCommissionReportsCount': 1,
          'activeStrikesCount': 1,
          'pendingMediationRequestsCount': 3,
          'paymentMethodsCount': 2,
          'aiEnabled': true,
        },
        'recentSales': [
          {
            'id': 's-1',
            'storeName': 'Mi Tienda',
            'amount': 50,
            'currency': 'USD',
            'time': '1:00 PM',
            'orderId': 'ord-1',
            'status': 'FULLY_PAID',
            'itemTitle': 'Teclado Mecánico',
          }
        ],
        'pendingOrders': [
          {
            'id': 'p-1',
            'orderId': 'ord-p-1',
            'customerName': 'Luis Rojas',
            'amount': 89.99,
            'currency': 'USD',
            'time': '4:20 PM',
            'status': 'PARTIALLY_PAID',
            'itemTitle': 'Monitor 24"',
          }
        ],
      });

      expect(model.stats.salesToday, 312.5);
      expect(model.stats.salesTodayPercentage, -12.5);
      expect(model.stats.pendingOrdersCount, 5);
      expect(model.stats.openDisputesCount, 2);
      expect(model.stats.commissionDebt, 19.75);
      expect(model.stats.pendingCommissionReportsCount, 1);
      expect(model.stats.activeStrikesCount, 1);
      expect(model.stats.pendingMediationRequestsCount, 3);
      expect(model.stats.paymentMethodsCount, 2);
      expect(model.stats.aiEnabled, isTrue);
      expect(model.pendingOrders, hasLength(1));
      expect(model.pendingOrders.first.customerName, 'Luis Rojas');
      expect(model.pendingOrders.first.amount, 89.99);
    });

    test('gracefully defaults missing additive fields for legacy responses', () {
      final legacy = StoreDashboardModel.fromJson({
        'stats': {
          'salesToday': {'amount': 120, 'currency': 'USD'},
          'totalItems': 10,
          'totalCategories': 3,
          'totalCustomers': 8,
        },
        'recentSales': const [],
      });

      expect(legacy.stats.salesToday, 120.0);
      expect(legacy.stats.salesTodayPercentage, 0.0);
      expect(legacy.stats.pendingOrdersCount, 0);
      expect(legacy.stats.openDisputesCount, 0);
      expect(legacy.stats.commissionDebt, 0.0);
      expect(legacy.stats.aiEnabled, isFalse);
      expect(legacy.pendingOrders, isEmpty);
    });
  });

  group('StoreDetailsScreen Bento UX', () {
    testWidgets(
        'Owner view renders borderless Bento identity, alerts, KPIs (+Bs & clean delta), hub above ranking, and activity at 320px @ 1.35x without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          user: ownerUser,
          detailsData: const StoreDetailsData(
            store: sampleStore,
            dashboard: sampleDashboard,
            isLoading: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Identity & collapsible header controls
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byType(StoreDetailsIdentityCard), findsOneWidget);
      expect(find.text('+58 412 5550101'), findsOneWidget);
      expect(find.text('Av. Bolívar, Centro'), findsOneWidget);
      expect(find.byTooltip('Compartir enlace público'), findsOneWidget);
      expect(find.byTooltip('Gestión y configuración de sucursal'), findsOneWidget);
      expect(find.byKey(const ValueKey('gear_attention_dot')), findsOneWidget);
      expect(find.text('Gestión de Sucursal'), findsNothing);

      // Urgent alerts strip
      expect(find.byType(StoreUrgentAlertsStrip), findsOneWidget);
      expect(find.text('1 reclamo abierto'), findsOneWidget);
      expect(find.text('3 órdenes pendientes'), findsOneWidget);
      expect(find.text('1 strike activo'), findsOneWidget);
      expect(find.text('2 mediaciones pendientes'), findsOneWidget);

      // Configured branch hides setup readiness card
      expect(find.text('Prepara tu sucursal'), findsNothing);

      // KPI hero & delta + secondary tiles
      await tester.scrollUntilVisible(
        find.text('Métricas Clave'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(StoreDetailsMetricsBento), findsOneWidget);
      expect(find.text('Ventas de hoy'), findsOneWidget);
      expect(find.text('+25.0%'), findsOneWidget);
      expect(find.textContaining('Bs.'), findsWidgets);
      expect(find.text('Por atender'), findsOneWidget);
      expect(find.text('Gestión de Sucursal'), findsNothing);

      // Verify gamification sits directly below Métricas Clave (no inline hub between them)
      await tester.scrollUntilVisible(
        find.byType(StoreRankHeaderCard),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      final metricsTop =
          tester.getTopLeft(find.byType(StoreDetailsMetricsBento)).dy;
      final rankTop = tester.getTopLeft(find.byType(StoreRankHeaderCard)).dy;
      expect(metricsTop < rankTop, isTrue);

      // Verify activity section (Por Atender + Ventas Recientes)
      await tester.scrollUntilVisible(
        find.text('Ventas Recientes'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(StoreDetailsActivitySection), findsOneWidget);
      expect(find.text('Camisa Oxford'), findsOneWidget);
      expect(find.text('Zapatillas Urbanas'), findsOneWidget);

      // Open Bento Gear Bottom Sheet from sticky SliverAppBar and navigate to /payment-methods
      await tester.tap(find.byTooltip('Gestión y configuración de sucursal'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StoreDetailsManagementSheet), findsOneWidget);
      expect(find.text('Gestión de Sucursal'), findsOneWidget);
      expect(find.text('Operación Diaria'), findsOneWidget);
      expect(find.text('Crecimiento y Finanzas'), findsOneWidget);
      expect(find.text('Seguridad y Ajustes'), findsOneWidget);
      expect(find.text('Reclamos'), findsOneWidget);
      expect(find.text('Estudio IA'), findsOneWidget);
      expect(find.text('Activa'), findsWidgets);
      expect(find.text('Comisiones'), findsOneWidget);
      expect(find.text('2 rev.'), findsOneWidget);
      expect(find.text('Métodos de Pago'), findsOneWidget);

      final sheetScrollable = find.descendant(
        of: find.byType(StoreDetailsManagementSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Configuración de Tienda'),
        150,
        scrollable: sheetScrollable,
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Salud'), findsOneWidget);
      expect(find.text('1 str.'), findsOneWidget);
      expect(find.text('Mediaciones'), findsOneWidget);
      expect(find.text('Clientes Bloqueados'), findsOneWidget);
      expect(find.text('Configuración de Tienda'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Métodos de Pago'),
        -150,
        scrollable: sheetScrollable,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Métodos de Pago'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('dest:payment-methods'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Healthy branch renders gear without urgency dot and navigates safely to Configuración de Tienda (/settings)',
        (tester) async {
      const healthyStore = Store(
        id: 'store-1',
        name: 'Tu Lojita',
        branchName: 'Centro',
        hasMultipleBranches: true,
        logo: '',
        status: 'ACTIVE',
        productsCount: 12,
        pendingOrdersCount: 0,
        commissionDebt: 0,
        pendingCommissionReportsCount: 0,
        aiEnabled: false,
      );

      const healthyDashboard = StoreDashboard(
        stats: StoreStats(
          salesToday: 120,
          salesTodayPercentage: 0,
          currency: 'USD',
          totalItems: 12,
          totalCategories: 3,
          totalCustomers: 15,
          pendingOrdersCount: 0,
          openDisputesCount: 0,
          commissionDebt: 0,
          pendingCommissionReportsCount: 0,
          activeStrikesCount: 0,
          pendingMediationRequestsCount: 0,
          paymentMethodsCount: 2,
          aiEnabled: false,
        ),
        recentSales: [],
        pendingOrders: [],
      );

      await tester.pumpWidget(
        wrapViewport(
          width: 360,
          user: ownerUser,
          detailsData: const StoreDetailsData(
            store: healthyStore,
            dashboard: healthyDashboard,
            isLoading: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Gestión y configuración de sucursal'), findsOneWidget);
      expect(find.byKey(const ValueKey('gear_attention_dot')), findsNothing);

      await tester.tap(find.byTooltip('Gestión y configuración de sucursal'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StoreDetailsManagementSheet), findsOneWidget);
      final sheetScrollable = find.descendant(
        of: find.byType(StoreDetailsManagementSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Configuración de Tienda'),
        150,
        scrollable: sheetScrollable,
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Configuración de Tienda'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('dest:settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'formatSignedPercentage formats negative and zero values cleanly without "+-"',
        (tester) async {
      expect(formatSignedPercentage(-14.2), '-14.2%');
      expect(formatSignedPercentage(0.0), 'Sin cambios');
      expect(formatSignedPercentage(8.5), '+8.5%');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(dualExchangeRate)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StoreDetailsMetricsBento(
                stats: const StoreStats(
                  salesToday: 90,
                  salesTodayPercentage: -14.2,
                  currency: 'USD',
                  totalItems: 4,
                  totalCategories: 1,
                  totalCustomers: 3,
                  pendingOrdersCount: 1,
                ),
                canViewFinancials: true,
                canViewOrders: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-14.2%'), findsOneWidget);
      expect(find.textContaining('+-'), findsNothing);
    });

    testWidgets(
        'Unconfigured active store renders StoreReadinessChecklistCard with actionable steps',
        (tester) async {
      await tester.pumpWidget(
        wrapViewport(
          width: 360,
          user: ownerUser,
          detailsData: StoreDetailsData(
            store: const Store(
              id: 'store-1',
              name: 'Nueva Tienda',
              logo: '',
              status: 'ACTIVE',
            ),
            dashboard: const StoreDashboard(
              stats: StoreStats(
                salesToday: 0,
                currency: 'USD',
                totalItems: 0,
                totalCategories: 0,
                totalCustomers: 0,
                paymentMethodsCount: 0,
              ),
              recentSales: [],
              pendingOrders: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoreReadinessChecklistCard), findsOneWidget);
      expect(find.text('Prepara tu sucursal'), findsOneWidget);
      expect(find.text('Crea tu primera categoría'), findsOneWidget);
      expect(find.text('Publica tu primer artículo'), findsOneWidget);
      expect(find.text('Configura un método de pago'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Collaborator lacking financial/branch permissions hides monetary hero & restricted modules cleanly at 320px @ 1.35x',
        (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const restrictedDashboard = StoreDashboard(
        stats: StoreStats(
          salesToday: 0,
          currency: 'USD',
          totalItems: 18,
          totalCategories: 5,
          totalCustomers: 42,
          pendingOrdersCount: 3,
          openDisputesCount: 0,
          commissionDebt: 0,
          pendingCommissionReportsCount: 0,
          activeStrikesCount: 1,
          pendingMediationRequestsCount: 0,
          paymentMethodsCount: 2,
          aiEnabled: false,
        ),
        recentSales: [],
        pendingOrders: [
          StorePendingOrder(
            id: 'ord-p1',
            orderId: 'ord-p1',
            customerName: 'Cliente',
            amount: 45.0,
            currency: 'USD',
            time: '3:10 PM',
            status: 'PENDING',
            itemTitle: 'Camisa Oxford',
          ),
        ],
      );

      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          user: limitedOrderCollab,
          detailsData: const StoreDetailsData(
            store: sampleStore,
            dashboard: restrictedDashboard,
            isLoading: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Gear button IS visible to team members with urgency dot, inline Gestión de Sucursal is absent
      expect(find.byTooltip('Gestión y configuración de sucursal'), findsOneWidget);
      expect(find.byKey(const ValueKey('gear_attention_dot')), findsOneWidget);
      expect(find.byTooltip('Compartir enlace público'), findsOneWidget);
      expect(find.text('Gestión de Sucursal'), findsNothing);

      // Financial data completely hidden
      expect(find.text('Ventas de hoy'), findsNothing);
      expect(find.textContaining('Bs.'), findsNothing);
      expect(find.text('Comisiones'), findsNothing);
      expect(find.text('Estudio IA'), findsNothing);
      expect(find.text('Métodos de Pago'), findsNothing);

      // Operational KPIs & permitted hub items shown
      expect(find.text('Métricas Clave'), findsOneWidget);
      expect(find.text('Por atender'), findsOneWidget);
      expect(find.text('Artículos'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Clientes'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Por Atender'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Camisa Oxford'), findsOneWidget);
      expect(find.text('Ventas Recientes'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Collaborator with orders:view + metrics:view_sales_history (no financials/branches) sees titles without any money amounts, sees Salud without Mediaciones/Bloqueados, and sees deletion banner without reactivate button',
        (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const opsSalesCollab = User(
        id: 'collab-ops-sales',
        email: 'ops@tulojita.com',
        firstName: 'Lucía',
        lastName: 'Operaciones',
        role: 'COLLABORATOR',
        isCollaborator: true,
        company: company,
        allowedBranchIds: ['store-1'],
        permissions: [
          'branches:view',
          'orders:view',
          'metrics:view_sales_history',
        ],
        aiAllowedStoreIds: [],
      );

      final scheduledDeletionStore = Store(
        id: 'store-1',
        name: 'Tu Lojita',
        branchName: 'Centro',
        address: 'Av. Bolívar, Centro',
        phone: '+58 412 5550101',
        hasMultipleBranches: true,
        logo: '',
        status: 'INACTIVE',
        productsCount: 18,
        deletionScheduledAt: DateTime.now().add(const Duration(days: 5)),
      );

      const opsDashboard = StoreDashboard(
        stats: StoreStats(
          salesToday: 0,
          currency: 'USD',
          totalItems: 18,
          totalCategories: 5,
          totalCustomers: 42,
          pendingOrdersCount: 3,
          openDisputesCount: 0,
          commissionDebt: 0,
          pendingCommissionReportsCount: 0,
          activeStrikesCount: 1,
          pendingMediationRequestsCount: 2,
          paymentMethodsCount: 2,
          aiEnabled: false,
        ),
        recentSales: [
          StoreRecentSale(
            id: 'ord-r1',
            storeName: 'Tu Lojita',
            amount: 0,
            currency: 'USD',
            time: '2:15 PM',
            orderId: 'ord-r1',
            status: 'FULLY_PAID',
            itemTitle: 'Zapatillas Urbanas',
          ),
        ],
        pendingOrders: [
          StorePendingOrder(
            id: 'ord-p1',
            orderId: 'ord-p1',
            customerName: 'Cliente',
            amount: 0,
            currency: 'USD',
            time: '3:10 PM',
            status: 'PENDING',
            itemTitle: 'Camisa Oxford',
          ),
        ],
      );

      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          user: opsSalesCollab,
          detailsData: StoreDetailsData(
            store: scheduledDeletionStore,
            dashboard: opsDashboard,
            isLoading: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Scheduled deletion warning visible to team, recovery button hidden without branches:manage
      expect(find.text('Baja Programada Activa'), findsOneWidget);
      expect(find.text('Cancelar Eliminación y Reactivar'), findsNothing);

      // Strikes allowed, Mediaciones alert stripped for collaborators
      await tester.scrollUntilVisible(
        find.text('Atención Prioritaria'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 strike activo'), findsOneWidget);
      expect(find.textContaining('mediaci'), findsNothing);

      // Inline Gestión de Sucursal absent from scroll body
      expect(find.text('Gestión de Sucursal'), findsNothing);

      // Both activity sections visible with item titles, ZERO money figures
      await tester.scrollUntilVisible(
        find.text('Por Atender'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Camisa Oxford'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Ventas Recientes'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Zapatillas Urbanas'), findsOneWidget);

      expect(find.text('Ventas de hoy'), findsNothing);
      expect(find.textContaining('\$'), findsNothing);
      expect(find.textContaining('Bs.'), findsNothing);

      // Open gear bottom sheet and verify collaborator permission isolation
      await tester.tap(find.byTooltip('Gestión y configuración de sucursal'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(StoreDetailsManagementSheet), findsOneWidget);
      final sheetScrollable = find.descendant(
        of: find.byType(StoreDetailsManagementSheet),
        matching: find.byType(Scrollable),
      );
      expect(find.text('Órdenes'), findsOneWidget);
      expect(find.text('Mi Ranking'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Salud'),
        150,
        scrollable: sheetScrollable,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Salud'), findsOneWidget);
      expect(find.text('1 str.'), findsOneWidget);
      expect(find.text('Crecimiento y Finanzas'), findsNothing);
      expect(find.text('Estudio IA'), findsNothing);
      expect(find.text('Comisiones'), findsNothing);
      expect(find.text('Métodos de Pago'), findsNothing);
      expect(find.text('Mediaciones'), findsNothing);
      expect(find.text('Clientes Bloqueados'), findsNothing);
      expect(find.text('Configuración de Tienda'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
