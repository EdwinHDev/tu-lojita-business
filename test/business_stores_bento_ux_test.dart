import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/dashboard/data/models/store_model.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/notification.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/views/stores_view.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_empty_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_list_tile.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/stores/single_store_quick_actions_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/stores/stores_header_banner.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/stores/stores_shimmer_skeleton.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/stores/stores_summary_bento_card.dart';
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

class _FakeStoresNotifier extends StoresNotifier {
  final StoresState _state;
  _FakeStoresNotifier(this._state);

  @override
  StoresState build() => _state;

  @override
  Future<void> loadData() async {}
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

  const restrictedOrdersCollab = User(
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

  const enabledRate = ExchangeRateConfig(enabled: true, rate: 50.0);
  const disabledRate = ExchangeRateConfig(enabled: false, rate: 0.0);

  const urgentStore = Store(
    id: 'store-1',
    name: 'Tu Lojita',
    branchName: 'Centro',
    address: 'Av. Central 100',
    logo: '/s1.png',
    status: 'ACTIVE',
    productsCount: 18,
    salesToday: 1250.50,
    hasMultipleBranches: true,
    aiEnabled: true,
    pendingOrdersCount: 3,
    commissionDebt: 24.50,
    pendingCommissionReportsCount: 1,
    rankingDivisionTitle: 'Tienda de Marca',
    currentPR: 420,
    consecutiveSalesDays: 7,
    inDangerZone: true,
  );

  const healthyStore = Store(
    id: 'store-2',
    name: 'Tu Lojita',
    branchName: 'Norte',
    address: 'Av. Bolívar 200',
    logo: '/s2.png',
    status: 'ACTIVE',
    productsCount: 9,
    salesToday: 300.0,
    hasMultipleBranches: true,
  );

  const inactiveStore = Store(
    id: 'store-3',
    name: 'Tu Lojita',
    branchName: 'Oeste',
    address: 'CC Oeste Local 4',
    logo: '/s3.png',
    status: 'INACTIVE',
    productsCount: 5,
    salesToday: 0.0,
    hasMultipleBranches: true,
  );

  const fourthStore = Store(
    id: 'store-4',
    name: 'Boutique Sur',
    branchName: 'Sur',
    address: 'Urb. El Sur',
    logo: '/s4.png',
    status: 'ACTIVE',
    productsCount: 12,
    salesToday: 120.0,
    hasMultipleBranches: true,
  );

  DashboardStats sampleStats({double percentage = 15.4}) => DashboardStats(
        salesToday: SalesStats(
          amount: 1670.50,
          percentage: percentage,
          currency: 'USD',
        ),
        totalStores: const CountStats(count: 4, increment: 1),
        totalProducts: const CountStats(count: 44, increment: 3),
        totalCustomers: const CountStats(count: 20, increment: 4),
      );

  Widget wrapViewport({
    required Widget child,
    double width = 320,
    double textScale = 1.0,
    User user = ownerUser,
    ExchangeRateConfig rateConfig = enabledRate,
    StoresState? storesState,
    List<AppNotification> notifications = const [],
    bool aiGlobalEnabled = true,
  }) {
    final effectiveStoresState = storesState ??
        StoresState(
          stores: const [urgentStore, healthyStore],
          stats: sampleStats(),
        );

    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith(() => _FakeAuthNotifier(user)),
        exchangeRateProvider
            .overrideWith(() => _FakeExchangeRateNotifier(rateConfig)),
        notificationsProvider
            .overrideWith(() => _FakeNotificationsNotifier(notifications)),
        storesProvider
            .overrideWith(() => _FakeStoresNotifier(effectiveStoresState)),
        platformAiGlobalEnabledProvider
            .overrideWith((ref) async => aiGlobalEnabled),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 600),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }

  group('Task 2.1 - StoreModel & unreadBusinessDisputeCountByStoreProvider', () {
    test('StoreModel.fromJson parses enriched fields and safe legacy defaults',
        () {
      final full = StoreModel.fromJson({
        'id': 'store-1',
        'name': 'Tu Lojita',
        'branchName': 'Centro',
        'logo': '/s1.png',
        'status': 'ACTIVE',
        'productsCount': 12,
        'salesToday': 350.75,
        'pendingOrdersCount': 4,
        'commissionDebt': 19.25,
        'pendingCommissionReportsCount': 2,
        'rankingDivisionTitle': 'Tienda de Marca',
        'currentPR': 510,
        'consecutiveSalesDays': 11,
        'inDangerZone': true,
      });

      expect(full.pendingOrdersCount, 4);
      expect(full.commissionDebt, 19.25);
      expect(full.pendingCommissionReportsCount, 2);
      expect(full.rankingDivisionTitle, 'Tienda de Marca');
      expect(full.currentPR, 510);
      expect(full.consecutiveSalesDays, 11);
      expect(full.inDangerZone, isTrue);

      final legacy = StoreModel.fromJson({
        'id': 'store-2',
        'name': 'Sucursal Legacy',
        'logo': '',
        'status': 'ACTIVE',
      });
      expect(legacy.pendingOrdersCount, 0);
      expect(legacy.commissionDebt, 0.0);
      expect(legacy.pendingCommissionReportsCount, 0);
      expect(legacy.rankingDivisionTitle, isNull);
      expect(legacy.currentPR, 0);
      expect(legacy.consecutiveSalesDays, 0);
      expect(legacy.inDangerZone, isFalse);
    });

    test('unreadBusinessDisputeCountByStoreProvider counts unique disputed orders per store',
        () async {
      final notifs = [
        AppNotification(
          id: 'n1',
          title: 'Nuevo reclamo',
          body: 'Reclamo en pedido #1',
          type: 'MEDIATION_REQUEST',
          targetId: 'order-1',
          storeId: 'store-1',
          channelType: 'DISPUTE_BUYER_SELLER',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
        AppNotification(
          id: 'n2',
          title: 'Respuesta en reclamo',
          body: 'Cliente respondió en pedido #1',
          type: 'MEDIATION_RESPONSE',
          targetId: 'order-1',
          storeId: 'store-1',
          channelType: 'DISPUTE_BUYER_SELLER',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
        AppNotification(
          id: 'n3',
          title: 'Reclamo escalado',
          body: 'Reclamo escalado en orden #2',
          type: 'DISPUTE_ESCALATED',
          targetId: 'order-2',
          storeId: 'store-1',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
        AppNotification(
          id: 'n4',
          title: 'Mediación tienda',
          body: 'Bloqueo preventivo',
          type: 'MEDIATION_REQUEST',
          targetId: 'store-2',
          storeId: 'store-2',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
        AppNotification(
          id: 'n5',
          title: 'Reclamo ya leído',
          body: 'Reclamo resuelto',
          type: 'MEDIATION_REQUEST',
          targetId: 'order-9',
          storeId: 'store-2',
          channelType: 'DISPUTE_BUYER_SELLER',
          isRead: true,
          createdAt: DateTime(2026, 10, 1),
        ),
        AppNotification(
          id: 'n6',
          title: 'Reclamo sucursal 2',
          body: 'Nuevo reclamo en pedido #3',
          type: 'MEDIATION_REQUEST',
          targetId: 'order-3',
          storeId: 'store-2',
          channelType: 'DISPUTE_BUYER_SELLER',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          notificationsProvider
              .overrideWith(() => _FakeNotificationsNotifier(notifs)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(notificationsProvider.future);

      final countsByStore =
          container.read(unreadBusinessDisputeCountByStoreProvider);
      expect(countsByStore, {'store-1': 2, 'store-2': 1});
    });
  });

  group('Task 2.2 & 3.1 - Header Banner & Summary Bento Card', () {
    testWidgets(
        'StoresHeaderBanner renders BCV pill, 99+ >=44x44 bell, and permission-gated + Nueva at 320px 1.35x',
        (tester) async {
      final manyUnread = List.generate(
        120,
        (i) => AppNotification(
          id: 'n-$i',
          title: 'Alerta #$i',
          body: 'Nuevo pedido',
          type: 'ORDER_NEW',
          isRead: false,
          createdAt: DateTime(2026, 10, 1),
        ),
      );

      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          notifications: manyUnread,
          child: StoresHeaderBanner(
            storeCount: 2,
            canManageBranches: true,
            onCreateStore: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis Tiendas'), findsOneWidget);
      expect(find.text('2 sucursales autorizadas'), findsOneWidget);
      expect(find.text('+ Nueva'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('Tasa BCV: Bs. 50,00'), findsOneWidget);

      final bellInkWell = tester.getSize(
        find.ancestor(
          of: find.byType(Badge),
          matching: find.byType(InkWell),
        ),
      );
      expect(bellInkWell.width, greaterThanOrEqualTo(44.0));
      expect(bellInkWell.height, greaterThanOrEqualTo(44.0));
      expect(tester.takeException(), isNull);

      // Hide + Nueva when canManageBranches is false and BCV when disabled
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          rateConfig: disabledRate,
          child: StoresHeaderBanner(
            storeCount: 1,
            canManageBranches: false,
            onCreateStore: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mi Tienda'), findsOneWidget);
      expect(find.text('+ Nueva'), findsNothing);
      expect(find.textContaining('Tasa BCV'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'StoresSummaryBentoCard formats positive, negative without +-, zero, and hides financials for collaborators',
        (tester) async {
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          child: StoresSummaryBentoCard(
            stats: sampleStats(percentage: -18.5),
            stores: const [urgentStore, healthyStore],
            unreadDisputesByStore: const {'store-1': 1},
            canViewFinancials: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VENTAS DE HOY'), findsOneWidget);
      expect(find.text('\$ 1.670,50'), findsOneWidget);
      expect(find.text('~ Bs. 83.525,00'), findsOneWidget);
      expect(find.text('-18.5%'), findsOneWidget);
      expect(find.textContaining('+-'), findsNothing);
      expect(find.text('Sedes Activas'), findsOneWidget);
      expect(find.text('Con Atención'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Zero delta
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          child: StoresSummaryBentoCard(
            stats: sampleStats(percentage: 0),
            stores: const [urgentStore, healthyStore],
            unreadDisputesByStore: const {},
            canViewFinancials: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sin cambios'), findsOneWidget);

      // Collaborator without financial permission
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          child: StoresSummaryBentoCard(
            stats: sampleStats(percentage: 12),
            stores: const [urgentStore],
            unreadDisputesByStore: const {},
            canViewFinancials: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('VENTAS DE HOY'), findsNothing);
      expect(find.text('RESUMEN OPERATIVO'), findsOneWidget);
      expect(find.text('Sedes Autorizadas'), findsOneWidget);
      expect(find.textContaining('Bs.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Task 3.2 & 3.3 - StoreListTile, FiltersBar, SingleStore, Shimmer & EmptyState',
      () {
    testWidgets(
        'StoreListTile works standalone and renders balanced multi-badge scorecard at 320px 1.35x',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.35),
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StoreListTile(
                          store: urgentStore,
                          exchangeConfig: enabledRate,
                          unreadDisputesCount: 2,
                          canViewFinancials: true,
                          onTap: () {},
                        ),
                        StoreListTile(
                          store: healthyStore,
                          exchangeConfig: enabledRate,
                          unreadDisputesCount: 0,
                          canViewFinancials: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sucursal Centro'), findsOneWidget);
      expect(find.text('Activa'), findsNWidgets(2));
      expect(find.text('18 productos'), findsOneWidget);
      expect(find.text('Ventas hoy'), findsOneWidget);
      expect(find.text('\$ 1.250,50'), findsOneWidget);
      expect(find.text('~ Bs. 62.525,00'), findsOneWidget);
      expect(find.text('3 ped. pend.'), findsOneWidget);
      expect(find.text('2 reclamos'), findsOneWidget);
      expect(
        find.text('Comisión: \$ 24,50 (~ Bs. 1.225,00)'),
        findsOneWidget,
      );
      expect(find.text('1 pago rev.'), findsOneWidget);
      expect(find.text('En riesgo'), findsOneWidget);
      expect(
        find.text('Tienda de Marca (420 PR) · 7d racha · Estudio IA'),
        findsOneWidget,
      );
      // Healthy store hides alerts cleanly
      expect(find.text('Sucursal Norte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'StoresView renders multi-store filters (2+), local search (4+), and hides FAB',
        (tester) async {
      await tester.pumpWidget(
        wrapViewport(
          width: 340,
          textScale: 1.25,
          storesState: StoresState(
            stores: const [
              urgentStore,
              healthyStore,
              inactiveStore,
              fourthStore,
            ],
            stats: sampleStats(),
          ),
          notifications: [
            AppNotification(
              id: 'nd-1',
              title: 'Reclamo',
              body: 'Reclamo orden',
              type: 'MEDIATION_REQUEST',
              targetId: 'ord-d1',
              storeId: 'store-1',
              isRead: false,
              createdAt: DateTime(2026, 10, 1),
            ),
          ],
          child: const StoresView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Mis Tiendas'), findsOneWidget);
      expect(find.text('Todas (4)'), findsOneWidget);
      expect(find.text('Con atención (1)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Tap "Con atención (1)" -> narrows to urgentStore only
      await tester.ensureVisible(find.text('Con atención (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Con atención (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Sucursal Centro'), findsOneWidget);
      expect(find.text('Sucursal Norte'), findsNothing);

      // Switch back to Todas and search "Boutique"
      await tester.ensureVisible(find.text('Todas (4)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todas (4)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Boutique');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sucursal Sur'));
      expect(find.text('Sucursal Sur'), findsOneWidget);
      expect(find.text('Sucursal Centro'), findsNothing);

      // Unmatched query -> empty filter card + Limpiar filtros
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'NoExisteXYZ');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Ninguna sucursal coincide con el filtro'), findsOneWidget);
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sucursal Centro'));
      expect(find.text('Sucursal Centro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'StoresView renders SingleStoreQuickActionsCard for single store and restricts collaborator permissions',
        (tester) async {
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          user: ownerUser,
          aiGlobalEnabled: true,
          storesState: StoresState(
            stores: const [urgentStore],
            stats: sampleStats(),
          ),
          notifications: [
            AppNotification(
              id: 'nd-single',
              title: 'Reclamo',
              body: 'Reclamo pedido',
              type: 'DISPUTE_ESCALATED',
              targetId: 'ord-99',
              storeId: 'store-1',
              isRead: false,
              createdAt: DateTime(2026, 10, 1),
            ),
          ],
          child: const StoresView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi Tienda'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Gestión Directa'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text('Ajustes'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Gestión Directa'), findsOneWidget);
      expect(find.text('Órdenes'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // 3 pending + 1 dispute
      expect(find.text('Artículos'), findsOneWidget);
      expect(find.text('Cuotas'), findsOneWidget);
      expect(find.text('Estudio IA'), findsWidgets);
      expect(find.text('Mi Ranking'), findsOneWidget);
      expect(find.text('Comisiones'), findsOneWidget);
      expect(find.text('1 rev.'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);

      // Stacked 2-row Bento tiles must NOT truncate labels on 320px + 1.35x
      final ordersParagraph =
          tester.renderObject(find.text('Órdenes')) as RenderParagraph;
      final commissionsParagraph =
          tester.renderObject(find.text('Comisiones')) as RenderParagraph;
      expect(ordersParagraph.didExceedMaxLines, isFalse);
      expect(commissionsParagraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);

      // Debt with 0 pending reports must show 'Deuda', NEVER a fake '1' badge
      final debtOnlyStore = urgentStore.copyWith(
        pendingCommissionReportsCount: 0,
        commissionDebt: 30.0,
      );
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          user: ownerUser,
          storesState: StoresState(
            stores: [debtOnlyStore],
            stats: sampleStats(),
          ),
          child: const StoresView(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Comisiones'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: find.byType(SingleStoreQuickActionsCard),
          matching: find.text('Deuda'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SingleStoreQuickActionsCard),
          matching: find.text('1'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      // Collaborator restricted to orders:view
      await tester.pumpWidget(
        wrapViewport(
          width: 320,
          textScale: 1.35,
          user: restrictedOrdersCollab,
          storesState: StoresState(
            stores: const [urgentStore],
            stats: sampleStats(),
          ),
          child: const StoresView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Gestión Directa'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('+ Nueva'), findsNothing);
      expect(find.text('Órdenes'), findsOneWidget);
      expect(find.text('Mi Ranking'), findsOneWidget);
      expect(find.text('Artículos'), findsNothing);
      expect(find.text('Comisiones'), findsNothing);
      expect(find.text('Ajustes'), findsNothing);
      expect(find.text('Estudio IA'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'StoresView shows StoresShimmerSkeleton when loading and hides CTA in StoreEmptyState without permission',
        (tester) async {
      await tester.pumpWidget(
        wrapViewport(
          storesState: const StoresState(stores: [], isLoading: true),
          child: const StoresView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(StoresShimmerSkeleton), findsOneWidget);
      expect(find.byType(ShimmerWidget), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        wrapViewport(
          user: restrictedOrdersCollab,
          storesState: const StoresState(stores: [], isLoading: false),
          child: const StoresView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StoreEmptyState), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StoreEmptyState),
          matching: find.text('Sin sucursales asignadas'),
        ),
        findsOneWidget,
      );
      expect(find.text('Crear mi primera tienda'), findsNothing);
      expect(find.text('+ Nueva'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'StoreModel safely defaults null logo and StoreListTile/StoresHeaderBanner render company logo fallback',
        (tester) async {
      final parsedNullLogo = StoreModel.fromJson({
        'id': 'store-null-logo',
        'name': 'Sucursal Sin Logo',
        'logo': null,
        'status': 'ACTIVE',
      });
      expect(parsedNullLogo.logo, '');

      await tester.pumpWidget(
        wrapViewport(
          storesState: StoresState(
            stores: [parsedNullLogo],
            stats: sampleStats(),
          ),
          child: const StoresView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final headerImages = tester.widgetList<Image>(
        find.descendant(
          of: find.byType(StoresHeaderBanner),
          matching: find.byType(Image),
        ),
      );
      expect(
        headerImages.any(
          (img) =>
              img.image is NetworkImage &&
              (img.image as NetworkImage).url ==
                  'https://images.tulojita.com/company-logo.png',
        ),
        isTrue,
      );

      final tileImages = tester.widgetList<Image>(
        find.descendant(
          of: find.byType(StoreListTile),
          matching: find.byType(Image),
        ),
      );
      expect(
        tileImages.any(
          (img) =>
              img.image is NetworkImage &&
              (img.image as NetworkImage).url ==
                  'https://images.tulojita.com/company-logo.png',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
