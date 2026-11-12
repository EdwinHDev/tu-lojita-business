import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_attention_banner.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_details_identity_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_suspension_banner_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_urgent_alerts_strip.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_list_tile.dart';
import 'widget_test.dart';

class _FakeExchangeRateNotifier extends ExchangeRateNotifier {
  final ExchangeRateConfig _config;
  _FakeExchangeRateNotifier(this._config);

  @override
  Future<ExchangeRateConfig> build() async => _config;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  const enabledRate = ExchangeRateConfig(enabled: true, rate: 50.0);

  const ownerUser = User(
    id: 'owner-1',
    email: 'owner@test.com',
    firstName: 'Edwin',
    lastName: 'Morales',
    role: 'COMPANY',
    isCollaborator: false,
  );

  const nonFinancialCollab = User(
    id: 'collab-1',
    email: 'ops@test.com',
    firstName: 'Carlos',
    lastName: 'Ops',
    role: 'COLLABORATOR',
    isCollaborator: true,
    hasFullBranchAccess: true,
    permissions: ['orders:view'],
  );

  const suspendedDebtStore = Store(
    id: 'store-susp',
    name: 'Comercial Tu Lojita',
    branchName: 'Centro',
    logo: '',
    status: 'SUSPENDED',
    productsCount: 12,
    commissionDebt: 33.0,
    hasMultipleBranches: true,
  );

  const suspendedReviewStore = Store(
    id: 'store-rev',
    name: 'Comercial Tu Lojita',
    branchName: 'Norte',
    logo: '',
    status: 'SUSPENDED',
    productsCount: 5,
    commissionDebt: 33.0,
    pendingCommissionReportsCount: 1,
    hasMultipleBranches: true,
  );

  group('StoreListTile suspended UX', () {
    testWidgets(
      'renders Suspendida chip and debt pill for financial user at 320px @ 1.35x without overflow',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.35),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: ListView(
                  children: [
                    StoreListTile(
                      store: suspendedDebtStore,
                      exchangeConfig: enabledRate,
                      canViewFinancials: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suspendida'), findsOneWidget);
        expect(find.text('Activa'), findsNothing);
        expect(find.text('Desactivada'), findsNothing);
        expect(find.textContaining('Deuda:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'hides monetary debt and shows Regularización pendiente for restricted collaborators',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoreListTile(
                store: suspendedDebtStore,
                exchangeConfig: enabledRate,
                canViewFinancials: false,
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suspendida'), findsOneWidget);
        expect(find.text('Regularización pendiente'), findsOneWidget);
        expect(find.textContaining('Deuda:'), findsNothing);
        expect(find.textContaining('Comisión:'), findsNothing);
      },
    );

    testWidgets('prioritizes Pago en revisión when report is pending', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreListTile(
              store: suspendedReviewStore,
              exchangeConfig: enabledRate,
              canViewFinancials: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suspendida'), findsOneWidget);
      expect(find.text('Pago en revisión'), findsOneWidget);
    });
  });

  group('HomeAttentionBanner suspended origin pill', () {
    testWidgets('surfaces Suspendida pill and navigates to debts route on tap',
        (tester) async {
      String? pushedLocation;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: HomeAttentionBanner(
                user: ownerUser,
                pendingOrders: 0,
                unreadDisputesCount: 0,
                summary: const OperationalSummary(
                  totalCommissionDebt: 33.0,
                  storesWithDebtCount: 1,
                ),
                stores: const [suspendedDebtStore],
                selectedStoreId: 'all',
                canViewFinancials: true,
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId/debts',
            builder: (context, state) {
              pushedLocation = state.uri.toString();
              return const Scaffold(body: Text('Debts Hub'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider.overrideWith(
              () => _FakeExchangeRateNotifier(enabledRate),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suspendida · Centro'), findsOneWidget);
      await tester.tap(find.text('Suspendida · Centro'));
      await tester.pumpAndSettle();

      expect(pushedLocation, '/dashboard/stores/store-susp/debts');
    });

    testWidgets(
        'routes restricted collaborator to store details instead of debts route',
        (tester) async {
      String? pushedLocation;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: HomeAttentionBanner(
                user: nonFinancialCollab,
                pendingOrders: 0,
                unreadDisputesCount: 0,
                summary: const OperationalSummary(),
                stores: const [suspendedDebtStore],
                selectedStoreId: 'all',
                canViewFinancials: false,
              ),
            ),
          ),
          GoRoute(
            path: '/dashboard/stores/:storeId',
            builder: (context, state) {
              pushedLocation = state.uri.toString();
              return const Scaffold(body: Text('Store Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider.overrideWith(
              () => _FakeExchangeRateNotifier(enabledRate),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suspendida · Centro'));
      await tester.pumpAndSettle();

      expect(pushedLocation, '/dashboard/stores/store-susp');
    });
  });

  group('StoreDetails Suspension Card & Strip deduplication', () {
    testWidgets(
      'IdentityCard shows Suspendida chip and SuspensionBanner shows 1-2-3 steps + Pagar y reactivar CTA',
      (tester) async {
        var tappedPay = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              exchangeRateProvider.overrideWith(
                () => _FakeExchangeRateNotifier(enabledRate),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      const StoreDetailsIdentityCard(store: suspendedDebtStore),
                      StoreSuspensionBannerCard(
                        store: suspendedDebtStore,
                        canViewFinancials: true,
                        onTapPayAndReactivate: () => tappedPay = true,
                        onOpenHealthSheet: () {},
                      ),
                      StoreUrgentAlertsStrip(
                        store: suspendedDebtStore,
                        stats: const StoreStats(
                          salesToday: 0,
                          currency: 'USD',
                          totalItems: 12,
                          totalCategories: 2,
                          totalCustomers: 4,
                          pendingOrdersCount: 1,
                          commissionDebt: 33.0,
                        ),
                        user: ownerUser,
                        onOpenHealthSheet: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suspendida'), findsOneWidget);
        expect(find.text('Desactivada'), findsNothing);
        expect(
          find.text('Tienda suspendida por mora en comisiones'),
          findsOneWidget,
        );
        expect(find.text('Pagar y reactivar'), findsOneWidget);
        expect(find.textContaining('33,00'), findsWidgets);
        // Strip keeps pending orders but avoids duplicate Deuda pill
        expect(find.text('1 orden pendiente'), findsOneWidget);
        expect(find.textContaining('Deuda:'), findsNothing);

        await tester.tap(find.text('Pagar y reactivar'));
        await tester.pump();
        expect(tappedPay, isTrue);
      },
    );
  });
}
