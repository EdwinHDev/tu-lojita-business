import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/premium_snackbar.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/collaborators/domain/entities/permission_item.dart';
import 'package:tu_lojita_business/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:tu_lojita_business/features/collaborators/presentation/screens/create_edit_role_screen.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/crm/data/repositories/crm_repository.dart';
import 'package:tu_lojita_business/features/crm/domain/entities/crm_entities.dart';
import 'package:tu_lojita_business/features/crm/presentation/providers/crm_providers.dart';
import 'package:tu_lojita_business/features/crm/presentation/screens/customer_crm_detail_screen.dart';
import 'package:tu_lojita_business/features/crm/presentation/screens/customers_crm_view.dart';
import 'package:tu_lojita_business/features/crm/presentation/widgets/create_targeted_offer_sheet.dart';
import 'package:tu_lojita_business/features/crm/presentation/widgets/crm_action_helpers.dart';
import 'package:tu_lojita_business/features/crm/presentation/widgets/crm_guides_catalog.dart';
import 'package:tu_lojita_business/features/crm/presentation/widgets/crm_status_helpers.dart';
import 'package:tu_lojita_business/features/crm/presentation/widgets/crm_tutorial_carousel.dart';
import 'package:tu_lojita_business/features/crm/presentation/widgets/customer_crm_bento_card.dart';

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
}

class _FakeCrmRepository extends CrmRepository {
  _FakeCrmRepository() : super(Dio());

  @override
  Future<void> addCustomerNote(
    String companyId,
    String customerId, {
    required String content,
    String category = 'GENERAL',
  }) async {}

  @override
  Future<void> updateCustomerProfile(
    String companyId,
    String customerId, {
    List<String>? tags,
    String? preferredChannel,
    DateTime? nextFollowUpAt,
    bool clearFollowUp = false,
    String? nextFollowUpNote,
    bool? isFollowUpCompleted,
    bool? markContactedNow,
  }) async {}

  @override
  Future<CrmTargetedOfferSummary> createTargetedOffer(
    String companyId,
    String customerId, {
    required String itemId,
    required double offerPrice,
    required int durationHours,
    String? paymentMethod,
    String? paymentReference,
    String? messageToCustomer,
  }) async {
    return CrmTargetedOfferSummary(
      id: 'offer-1',
      offerCode: 'VIP-15OFF',
      itemId: itemId,
      itemTitle: 'Audífonos Pro ANC',
      originalPrice: 40.0,
      offerPrice: offerPrice,
      discountPercent: ((40.0 - offerPrice) / 40.0) * 100,
      durationHours: durationHours,
      status: 'ACTIVE',
      serviceFeeUsd: 0,
      expiresAt: DateTime(2026, 11, 15),
      deepLinkUrl: 'tulojita://offer/VIP-15OFF',
      whatsappShareText: 'Oferta VIP-15OFF',
      createdAt: DateTime(2026, 11, 13),
    );
  }

  @override
  Future<void> cancelOffer(String companyId, String offerId) async {}
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.test.com\nAPI_BASE_URL_IMAGES=https://images.test.com\n',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'crm_onboarding_seen_v1': true});
  });

  const company = Company(
    id: 'comp-1',
    name: 'Comercial Tu Lojita',
    rif: 'J-12345678-9',
    logo: '',
  );

  const ownerUser = User(
    id: 'u-owner',
    email: 'owner@tulojita.com',
    firstName: 'Ana',
    lastName: 'Dueña',
    role: 'COMPANY',
    hasCompany: true,
    company: company,
    isCollaborator: false,
  );

  const crmCollabUser = User(
    id: 'u-crm',
    email: 'crm@tulojita.com',
    firstName: 'Luis',
    lastName: 'Ventas',
    role: 'COMPANY',
    hasCompany: true,
    company: company,
    isCollaborator: true,
    collaboratorRole: 'Asesor CRM',
    hasFullBranchAccess: true,
    permissions: ['crm:access', 'crm:manage'],
  );

  const restrictedCollabUser = User(
    id: 'u-ops',
    email: 'ops@tulojita.com',
    firstName: 'Pedro',
    lastName: 'Caja',
    role: 'COMPANY',
    hasCompany: true,
    company: company,
    isCollaborator: true,
    collaboratorRole: 'Operador',
    hasFullBranchAccess: false,
    permissions: ['orders:view'],
  );

  final sampleFavorite = CrmFavoriteItem(
    favoriteId: 'fav-1',
    itemId: 'item-1',
    title: 'Audífonos Pro ANC',
    price: 40.0,
    discountPrice: null,
    priceWhenAdded: 40.0,
    mainImage: '',
    stockQuantity: 12,
    trackInventory: true,
    isActive: true,
    storeId: 'store-1',
    storeName: 'Sucursal Centro',
    favoritedAt: DateTime(2026, 11, 10),
  );

  final sampleCustomer = CrmCustomer(
    customerId: 'cust-1',
    fullName: 'María González',
    firstName: 'María',
    lastName: 'González',
    phone: '+584141234567',
    email: 'maria@example.com',
    identification: 'V-20123456',
    averageBuyerRating: 4.9,
    totalBuyerReviews: 6,
    isAccountSuspended: false,
    isChatBanned: false,
    primaryAddress: const CrmAddress(
      id: 'addr-1',
      title: 'Casa',
      fullAddress: 'Av. Bolívar con Calle 12',
      latitude: 10.48,
      longitude: -66.90,
      isActive: true,
    ),
    primaryStore: const CrmStoreRef(
      id: 'store-1',
      name: 'Tu Lojita',
      branchName: 'Centro',
    ),
    affiliatedStores: const [
      CrmAffiliatedStore(
        id: 'store-1',
        name: 'Tu Lojita',
        branchName: 'Centro',
        ordersCount: 4,
        ltvUsd: 160.0,
        favoritesCount: 1,
        isBlocked: false,
      ),
    ],
    ltvUsd: 160.0,
    ordersCount: 4,
    completedOrdersCount: 4,
    averageTicketUsd: 40.0,
    lastOrderAt: DateTime(2026, 11, 8),
    firstOrderAt: DateTime(2026, 8, 1),
    pendingDebtUsd: 25.0,
    overdueInstallmentsCount: 0,
    favoritesCount: 1,
    topFavoriteItems: [sampleFavorite],
    activeOffersCount: 0,
    disputesCount: 0,
    isBlocked: false,
    segment: 'VIP',
    segments: const ['VIP', 'WITH_FAVORITES'],
    tags: const ['Mayorista'],
    preferredChannel: 'WHATSAPP',
    lastContactAt: DateTime(2026, 11, 9),
    nextFollowUpAt: DateTime(2026, 11, 12),
    nextFollowUpNote: 'Enviar catálogo nuevo',
    isFollowUpCompleted: false,
    hasOverdueFollowUp: true,
  );

  const sampleSummary = CrmSummary(
    totalCustomers: 12,
    vipCount: 3,
    frequentCount: 4,
    newCount: 2,
    atRiskCount: 2,
    wishlistOnlyCount: 1,
    withDebtCount: 2,
    blockedCount: 0,
    totalLtvUsd: 1250.0,
    totalPendingDebtUsd: 140.0,
    totalFavoritesCount: 9,
    activeTargetedOffersCount: 2,
    pendingFollowUpsCount: 3,
    overdueFollowUpsCount: 1,
    authorizedStores: [
      CrmStoreRef(id: 'store-1', name: 'Tu Lojita', branchName: 'Centro'),
    ],
    crmOfferEnabled: true,
    crmOfferFeePerCampaign: 0,
  );

  final sampleDetail = CrmCustomerDetail(
    customer: sampleCustomer,
    addresses: const [
      CrmAddress(
        id: 'addr-1',
        title: 'Casa',
        fullAddress: 'Av. Bolívar con Calle 12',
        latitude: 10.48,
        longitude: -66.90,
        isActive: true,
      ),
    ],
    notes: [
      CrmCustomerNote(
        id: 'note-1',
        authorName: 'Luis Ventas',
        content: 'Cliente interesada en audífonos Bluetooth',
        category: 'FOLLOW_UP',
        createdAt: DateTime(2026, 11, 10, 14, 30),
      ),
    ],
    favoriteItems: [sampleFavorite],
    targetedOffers: const [],
    orders: [
      CrmOrderSummary(
        id: 'ord-12345678',
        storeId: 'store-1',
        storeName: 'Tu Lojita (Centro)',
        status: 'COMPLETED',
        totalAmount: 40.0,
        finalAmount: 40.0,
        totalPaidAmount: 40.0,
        remainingBalance: 0.0,
        isPartialPayment: false,
        isFullyPaid: true,
        exchangeRate: 50.0,
        createdAt: DateTime(2026, 11, 8),
        items: const [
          {'title': 'Audífonos Pro ANC', 'quantity': 1, 'unitPrice': 40.0},
        ],
        installments: const [],
        payments: const [],
      ),
    ],
    slotBookings: const [],
    buyerReviews: const [],
    orderReviewsWritten: const [],
    disputes: const [],
    blocks: const [],
    crmOfferEnabled: true,
    crmOfferFeePerCampaign: 0,
  );

  Widget wrapWithApp(
    Widget child, {
    List<dynamic> overrides = const [],
    User? authUser,
  }) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith(() => _FakeAuthNotifier(authUser ?? ownerUser)),
        exchangeRateProvider.overrideWith(
          () => _FakeExchangeRateNotifier(
            const ExchangeRateConfig(enabled: true, rate: 50.0),
          ),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('CRM RBAC & Bento UX Tests', () {
    test('User RBAC getters grant CRM only to owner or crm permissions', () {
      expect(ownerUser.canAccessCrm, isTrue);
      expect(ownerUser.canManageCrm, isTrue);

      expect(crmCollabUser.canAccessCrm, isTrue);
      expect(crmCollabUser.canManageCrm, isTrue);

      expect(restrictedCollabUser.canAccessCrm, isFalse);
      expect(restrictedCollabUser.canManageCrm, isFalse);
    });

    testWidgets(
      'CustomersCrmView displays KPIs, RFM chips, store pills and CustomerCrmBentoCard',
      (tester) async {
        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView()),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mini CRM 360°'), findsOneWidget);
        expect(find.text('LTV Total'), findsOneWidget);
        expect(find.text('VIP (3)'), findsOneWidget);
        // Sucursal única autoseleccionada en DropdownButton aunque selectedStoreId sea null
        expect(find.text('Tu Lojita (Centro)'), findsWidgets);
        final dropdown = tester.widget<DropdownButton<String?>>(
          find.byType(DropdownButton<String?>),
        );
        expect(dropdown.value, 'store-1');
        expect(find.byType(CustomerCrmBentoCard), findsOneWidget);
        expect(find.text('María González'), findsOneWidget);
        expect(find.text('Mayorista'), findsOneWidget);
        expect(find.text('Oferta (1)'), findsOneWidget);
      },
    );

    test('resolveCrmImageUrl handles relative and absolute URLs safely', () {
      expect(
        resolveCrmImageUrl('/uploads/avatar.png'),
        'https://images.test.com/uploads/avatar.png',
      );
      expect(
        resolveCrmImageUrl('uploads/item.png'),
        'https://images.test.com/uploads/item.png',
      );
      expect(
        resolveCrmImageUrl('https://cdn.example.com/a.png'),
        'https://cdn.example.com/a.png',
      );
      expect(resolveCrmImageUrl('  '), isNull);
      expect(resolveCrmImageUrl(null), isNull);
    });

    testWidgets(
      'CustomerCrmDetailScreen renders 4 tabs including favorites and team notes',
      (tester) async {
        await tester.pumpWidget(
          wrapWithApp(
            const CustomerCrmDetailScreen(customerId: 'cust-1'),
            overrides: [
              crmCustomerDetailProvider(
                'cust-1',
              ).overrideWith((ref) async => sampleDetail),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('María González'), findsWidgets);
        expect(find.text('Resumen & Contacto'), findsOneWidget);
        expect(find.text('Favoritos & Ofertas'), findsOneWidget);
        expect(find.text('Pedidos, Reservas y Cuotas'), findsOneWidget);
        expect(find.text('Reputación & Gobernanza'), findsOneWidget);

        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(
          find.text('Cliente interesada en audífonos Bluetooth'),
          findsOneWidget,
        );

        await tester.tap(find.text('Favoritos & Ofertas'));
        await tester.pumpAndSettle();
        expect(find.text('Audífonos Pro ANC'), findsOneWidget);
        expect(find.text('Oferta'), findsOneWidget);
        expect(find.text('Ofertas Especiales Enviadas (0)'), findsOneWidget);
      },
    );

    testWidgets(
      'CreateTargetedOfferSheet shows free mode when fee=0 and payment fields when fee>0',
      (tester) async {
        const freeConfig = CrmOffersConfig(
          enabled: true,
          feePerCampaign: 0,
          platformPaymentMethods: [],
        );

        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: CreateTargetedOfferSheet(
                companyId: 'comp-1',
                customer: sampleCustomer,
                favoriteItems: [sampleFavorite],
              ),
            ),
            overrides: [
              crmOffersConfigProvider.overrideWith((ref) async => freeConfig),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Campaña promocional gratuita (\$0.00). Envía sin registro de pago.'),
          findsOneWidget,
        );
        expect(find.text('Tarifa de Plataforma por Campaña:'), findsNothing);

        const paidConfig = CrmOffersConfig(
          enabled: true,
          feePerCampaign: 1.5,
          platformPaymentMethods: [
            CrmPlatformPaymentMethod(
              id: 'pm-1',
              title: 'Pago Móvil Banesco',
              type: 'PAGO_MOVIL',
              accountDetails: {'phone': '04140000000'},
            ),
          ],
        );

        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: CreateTargetedOfferSheet(
                companyId: 'comp-1',
                customer: sampleCustomer,
                favoriteItems: [sampleFavorite],
              ),
            ),
            overrides: [
              crmOffersConfigProvider.overrideWith((ref) async => paidConfig),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tarifa de Plataforma por Campaña:'), findsOneWidget);
        expect(find.text('Referencia de Pago'), findsOneWidget);
      },
    );

    testWidgets(
      'CustomerCrmBentoCard renders Ficha branch safely without favorites, phone or address',
      (tester) async {
        final noFavoritesWithPhone = CrmCustomer(
          customerId: 'cust-2',
          fullName: 'Carlos Pérez',
          firstName: 'Carlos',
          lastName: 'Pérez',
          phone: '+584121112233',
          email: 'carlos@example.com',
          identification: 'V-18000111',
          averageBuyerRating: 4.5,
          totalBuyerReviews: 2,
          isAccountSuspended: false,
          isChatBanned: false,
          primaryAddress: null,
          primaryStore: sampleCustomer.primaryStore,
          affiliatedStores: sampleCustomer.affiliatedStores,
          ltvUsd: 80.0,
          ordersCount: 2,
          completedOrdersCount: 2,
          averageTicketUsd: 40.0,
          lastOrderAt: DateTime(2026, 11, 8),
          firstOrderAt: DateTime(2026, 10, 1),
          pendingDebtUsd: 0.0,
          overdueInstallmentsCount: 0,
          favoritesCount: 0,
          topFavoriteItems: const [],
          activeOffersCount: 0,
          disputesCount: 0,
          isBlocked: false,
          segment: 'FREQUENT',
          segments: const ['FREQUENT'],
          tags: const [],
          preferredChannel: 'WHATSAPP',
          isFollowUpCompleted: false,
          hasOverdueFollowUp: false,
        );

        final noFavoritesNoPhone = CrmCustomer(
          customerId: 'cust-3',
          fullName: 'Elena Ruiz',
          firstName: 'Elena',
          lastName: 'Ruiz',
          phone: '',
          email: 'elena@example.com',
          identification: 'V-22333444',
          averageBuyerRating: 0.0,
          totalBuyerReviews: 0,
          isAccountSuspended: false,
          isChatBanned: false,
          primaryAddress: null,
          primaryStore: sampleCustomer.primaryStore,
          affiliatedStores: sampleCustomer.affiliatedStores,
          ltvUsd: 25.0,
          ordersCount: 1,
          completedOrdersCount: 1,
          averageTicketUsd: 25.0,
          lastOrderAt: DateTime(2026, 11, 8),
          firstOrderAt: DateTime(2026, 11, 1),
          pendingDebtUsd: 0.0,
          overdueInstallmentsCount: 0,
          favoritesCount: 0,
          topFavoriteItems: const [],
          activeOffersCount: 0,
          disputesCount: 0,
          isBlocked: false,
          segment: 'NEW',
          segments: const ['NEW'],
          tags: const [],
          preferredChannel: 'EMAIL',
          isFollowUpCompleted: false,
          hasOverdueFollowUp: false,
        );

        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 322,
                  child: Column(
                    children: [
                      CustomerCrmBentoCard(
                        customer: noFavoritesNoPhone,
                        canManageCrm: true,
                        onOpenDetail: () {},
                      ),
                      const SizedBox(height: 12),
                      CustomerCrmBentoCard(
                        customer: noFavoritesWithPhone,
                        canManageCrm: true,
                        onOpenDetail: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Elena Ruiz'), findsOneWidget);
        expect(find.text('Carlos Pérez'), findsOneWidget);
        expect(find.text('WhatsApp'), findsOneWidget);
        expect(find.text('Ficha'), findsNWidgets(2));

        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView()),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith(
                (ref) async => [noFavoritesNoPhone],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Elena Ruiz'), findsOneWidget);
        expect(find.text('Ficha'), findsOneWidget);
      },
    );

    testWidgets(
      'CRM 4-slide tutorial opens once when active tab is unseen, persists flag, and reopens via header Guía',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        // When mounted inside IndexedStack with isActive=false, must NOT auto-open.
        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView(isActive: false)),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Directorio 360° por Sucursal'), findsNothing);

        // Switching to active triggers automatic 4-slide tutorial.
        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView(isActive: true)),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Directorio 360° por Sucursal'), findsOneWidget);
        expect(find.text('Saltar'), findsOneWidget);

        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Datos Exclusivos y Contacto 1-Toque'), findsOneWidget);
        expect(find.text('Atrás'), findsOneWidget);

        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Segmentos RFM, LTV y Alertas'), findsOneWidget);

        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Ofertas Relámpago en Favoritos'), findsOneWidget);
        expect(find.text('¡Comenzar!'), findsOneWidget);

        await tester.tap(find.text('¡Comenzar!'));
        await tester.pumpAndSettle();
        expect(find.text('Ofertas Relámpago en Favoritos'), findsNothing);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('crm_onboarding_seen_v1:u-owner'), isTrue);

        // Re-tap header [Guía] reopens the tutorial on demand.
        await tester.tap(find.byKey(const ValueKey('crm_header_guide_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Directorio 360° por Sucursal'), findsOneWidget);
        await tester.tap(find.text('Saltar'));
        await tester.pumpAndSettle();
        expect(find.text('Directorio 360° por Sucursal'), findsNothing);
      },
    );

    testWidgets(
      'CrmTutorialCarousel and CRM views render without overflow at 320px width and 1.3x text scale',
      (tester) async {
        await tester.pumpWidget(
          wrapWithApp(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: SizedBox(
                width: 320,
                height: 640,
                child: Scaffold(
                  body: CrmTutorialCarousel(onComplete: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Directorio 360° por Sucursal'), findsOneWidget);

        await tester.pumpWidget(
          wrapWithApp(
            const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: SizedBox(
                width: 320,
                height: 640,
                child: Scaffold(body: CustomersCrmView()),
              ),
            ),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Contextual Guía sheets open from RFM segments, CustomerCrmDetailScreen, CreateTargetedOfferSheet and CreateEditRoleScreen',
      (tester) async {
        Future<void> dismissGuide() async {
          await tester.ensureVisible(find.text('Entendido'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Entendido'));
          await tester.pumpAndSettle();
        }

        // 1. RFM Segments guide
        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView()),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('crm_rfm_guide_btn')));
        await tester.pumpAndSettle();
        expect(find.text(CrmGuidesCatalog.rfmSegments.title), findsOneWidget);
        await dismissGuide();

        // 2. Detail Screen privacy badge + reminders guide + favorites guide
        await tester.pumpWidget(
          wrapWithApp(
            const CustomerCrmDetailScreen(customerId: 'cust-1'),
            overrides: [
              crmCustomerDetailProvider(
                'cust-1',
              ).overrideWith((ref) async => sampleDetail),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Datos protegidos: solo visibles para tu empresa'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('detail_reminder_guide_btn')));
        await tester.pumpAndSettle();
        expect(
          find.text(CrmGuidesCatalog.followUpReminders.title),
          findsOneWidget,
        );
        await dismissGuide();

        await tester.tap(find.text('Favoritos & Ofertas'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('detail_favorites_guide_btn')));
        await tester.pumpAndSettle();
        expect(
          find.text(CrmGuidesCatalog.targetedOffers.title),
          findsOneWidget,
        );
        await dismissGuide();

        // 3. CreateTargetedOfferSheet guide
        const freeConfig = CrmOffersConfig(
          enabled: true,
          feePerCampaign: 0,
          platformPaymentMethods: [],
        );
        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: CreateTargetedOfferSheet(
                companyId: 'comp-1',
                customer: sampleCustomer,
                favoriteItems: [sampleFavorite],
              ),
            ),
            overrides: [
              crmOffersConfigProvider.overrideWith((ref) async => freeConfig),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('offer_sheet_guide_btn')));
        await tester.pumpAndSettle();
        expect(
          find.text(CrmGuidesCatalog.targetedOffers.title),
          findsOneWidget,
        );
        await dismissGuide();

        // 4. CreateEditRoleScreen CRM permission module guide
        await tester.pumpWidget(
          wrapWithApp(
            const CreateEditRoleScreen(),
            overrides: [
              permissionCatalogProvider.overrideWith(
                (ref) async => const [
                  PermissionItem(
                    key: 'crm:access',
                    module: 'crm',
                    name: 'Ver CRM',
                    description: 'Consultar clientes por sucursal',
                  ),
                  PermissionItem(
                    key: 'crm:manage',
                    module: 'crm',
                    name: 'Gestionar CRM',
                    description: 'Notas, etiquetas y ofertas',
                  ),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('role_crm_guide_btn')));
        await tester.pumpAndSettle();
        expect(
          find.text(CrmGuidesCatalog.rolePermissions.title),
          findsOneWidget,
        );
        expect(
          find.textContaining('crm:access'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Differentiated empty states reset filters cleanly and read-only CRM collaborator sees notice banner',
      (tester) async {
        // 1. Read-only collaborator notice + initial zero-customer onboarding checklist
        const readOnlyCrmUser = User(
          id: 'u-crm-ro',
          email: 'ro@tulojita.com',
          firstName: 'Marta',
          lastName: 'Consulta',
          role: 'COMPANY',
          hasCompany: true,
          company: company,
          isCollaborator: true,
          collaboratorRole: 'Consulta CRM',
          hasFullBranchAccess: true,
          permissions: ['crm:access'],
        );

        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView()),
            authUser: readOnlyCrmUser,
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Modo consulta'), findsOneWidget);
        expect(find.text('Aún no tienes clientes en el CRM'), findsOneWidget);
        expect(find.text('Ver guía del CRM'), findsOneWidget);

        // 2. Active filter empty state + Limpiar filtros reset
        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView()),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('VIP (3)'));
        await tester.pumpAndSettle();

        expect(find.text('Sin resultados para estos filtros'), findsOneWidget);
        expect(find.text('Limpiar filtros'), findsOneWidget);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(CustomersCrmView)),
        );
        expect(container.read(crmSelectedSegmentProvider), 'VIP');

        await tester.ensureVisible(find.text('Limpiar filtros'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Limpiar filtros'));
        await tester.pumpAndSettle();
        expect(container.read(crmSelectedSegmentProvider), isNull);
        expect(find.text('Aún no tienes clientes en el CRM'), findsOneWidget);
      },
    );

    testWidgets(
      'Explanatory confirmation feedback shown when saving internal notes or activating targeted offer',
      (tester) async {
        final fakeRepo = _FakeCrmRepository();

        await tester.pumpWidget(
          wrapWithApp(
            const CustomerCrmDetailScreen(customerId: 'cust-1'),
            overrides: [
              crmRepositoryProvider.overrideWithValue(fakeRepo),
              crmCustomerDetailProvider(
                'cust-1',
              ).overrideWith((ref) async => sampleDetail),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView).first, const Offset(0, -800));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.hintText?.contains('nota interna') == true,
          ),
          'Contactar el viernes',
        );
        await tester.tap(find.text('Guardar Nota'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PremiumSnackBarContent), findsOneWidget);
        expect(
          find.text(
            'Nota guardada en la bitácora interna (solo visible para tu empresa).',
          ),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        const freeConfig = CrmOffersConfig(
          enabled: true,
          feePerCampaign: 0,
          platformPaymentMethods: [],
        );
        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: CreateTargetedOfferSheet(
                companyId: 'comp-1',
                customer: sampleCustomer,
                favoriteItems: [sampleFavorite],
              ),
            ),
            overrides: [
              crmRepositoryProvider.overrideWithValue(fakeRepo),
              crmOffersConfigProvider.overrideWith((ref) async => freeConfig),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Activar y Enviar Oferta'));
        await tester.pumpAndSettle();

        expect(find.text('¡Oferta Especial Activada!'), findsOneWidget);
        expect(find.textContaining('notificación Push'), findsOneWidget);
        expect(find.textContaining('WhatsApp'), findsWidgets);
      },
    );

    test('CRM status helpers translate backend enums and format installments cleanly', () {
      expect(crmOrderStatusMeta('FULLY_PAID').label, 'Pagado completo');
      expect(crmOrderStatusMeta('PARTIALLY_PAID').label, 'Abono parcial');
      expect(crmOrderStatusMeta('PENDING_PAYMENT').label, 'Pendiente de pago');
      expect(crmOrderStatusMeta('PAYMENT_SUBMITTED').label, 'Pago reportado');
      expect(crmOrderStatusMeta('READY_FOR_PICKUP').label, 'Listo para retiro');
      expect(
        crmOrderStatusMeta('', preOrderStatus: 'AWAITING_STOCK').label,
        'Esperando stock',
      );
      expect(
        crmOrderStatusMeta('', preOrderStatus: 'NONE').label,
        'Sin estado',
      );
      expect(crmOrderStatusMeta('UNKNOWN_CUSTOM').label, 'Unknown Custom');

      expect(crmPreOrderStatusMeta('AWAITING_STOCK').label, 'Esperando stock');
      expect(crmPreOrderStatusMeta('STOCK_ARRIVED').label, 'Stock disponible');
      expect(
        crmPreOrderStatusMeta('READY_FOR_SETTLEMENT').label,
        'Listo para liquidar',
      );
      expect(crmPreOrderStatusMeta('FULFILLED').label, 'Completado');
      expect(crmPreOrderStatusMeta('CANCELLED').label, 'Pre-orden cancelada');
      expect(crmInstallmentStatusMeta('PAID').label, 'Pagada');
      expect(crmInstallmentStatusMeta('OVERDUE').label, 'Vencida');
      expect(
        formatOrderInstallmentsSummary(const [
          {'status': 'PAID'},
          {'status': 'PAID'},
          {'status': 'PENDING'},
        ]),
        '2/3 cuotas pagadas',
      );
      expect(
        formatOrderInstallmentsSummary(const [
          {'status': 'PAID'},
          {'status': 'OVERDUE'},
        ]),
        '1/2 cuotas pagadas (1 vencida)',
      );

      expect(crmSlotBookingStatusMeta('HOLD').label, 'En espera');
      expect(crmSlotBookingStatusMeta('CONFIRMED').label, 'Confirmada');
      expect(crmSlotBookingStatusMeta('COMPLETED').label, 'Completada');
      expect(crmSlotBookingStatusMeta('NO_SHOW').label, 'No asistió');
      expect(crmOfferStatusMeta('ACTIVE').label, 'Activa');
      expect(crmOfferStatusMeta('REDEEMED').label, 'Canjeada');
      expect(crmOfferStatusMeta('EXPIRED').label, 'Expirada');
      expect(crmOfferStatusMeta('CANCELLED').label, 'Cancelada');
      expect(crmDisputeTypeLabel('NO_SHOW'), 'Inasistencia a cita o retiro');
      expect(
        crmDisputeTypeLabel('REFUND_REQUEST'),
        'Solicitud de reembolso',
      );
      expect(crmDisputeTypeLabel('NOT_DELIVERED'), 'No entregado');
      expect(crmDisputeTypeLabel('DAMAGED_ITEM'), 'Producto dañado');
      expect(crmDisputeTypeLabel('WRONG_ITEM'), 'Producto equivocado');
      expect(crmDisputeStatusMeta('OPEN').label, 'Abierta');
      expect(
        crmDisputeStatusMeta('MERCHANT_RESPONDED').label,
        'Comercio respondió',
      );
      expect(
        crmDisputeStatusMeta('ADMIN_REVIEW').label,
        'En revisión admin',
      );
      expect(crmDisputeStatusMeta('REFUNDED').label, 'Reembolsada');
      expect(crmDisputeStatusMeta('REJECTED').label, 'Rechazada');
      expect(crmNoteCategoryMeta('FOLLOW_UP').label, 'Seguimiento');
      expect(crmNoteCategoryMeta('PAYMENT').label, 'Cobranza');
      expect(crmNoteCategoryMeta('VIP').label, 'Atención VIP');
    });

    testWidgets(
      'CustomerCrmDetailScreen renders localized Spanish badges without raw enums',
      (tester) async {
        final richDetail = CrmCustomerDetail(
          customer: sampleCustomer,
          addresses: sampleDetail.addresses,
          notes: sampleDetail.notes,
          favoriteItems: [sampleFavorite],
          targetedOffers: [
            CrmTargetedOfferSummary(
              id: 'offer-1',
              offerCode: 'VIP-30',
              itemId: 'item-1',
              itemTitle: 'Audífonos Pro ANC',
              originalPrice: 40.0,
              offerPrice: 28.0,
              discountPercent: 30.0,
              durationHours: 24,
              status: 'ACTIVE',
              serviceFeeUsd: 0,
              expiresAt: DateTime(2026, 11, 20),
              deepLinkUrl: 'tulojita://offer/VIP-30',
              whatsappShareText: 'VIP-30',
              createdAt: DateTime(2026, 11, 12),
            ),
          ],
          orders: [
            CrmOrderSummary(
              id: 'ord-paid',
              storeId: 'store-1',
              storeName: 'Tu Lojita (Centro)',
              status: 'FULLY_PAID',
              preOrderStatus: 'NONE',
              totalAmount: 90.0,
              finalAmount: 90.0,
              totalPaidAmount: 90.0,
              remainingBalance: 0.0,
              isPartialPayment: false,
              isFullyPaid: true,
              exchangeRate: 50.0,
              createdAt: DateTime(2026, 11, 8),
              items: const [
                {'title': 'Audífonos Pro ANC', 'quantity': 1, 'unitPrice': 90.0},
              ],
              installments: const [
                {'status': 'PAID'},
                {'status': 'PAID'},
                {'status': 'PENDING'},
              ],
              payments: const [],
            ),
          ],
          slotBookings: const [
            CrmSlotBookingSummary(
              id: 'bk-1',
              orderId: 'ord-paid',
              storeId: 'store-1',
              storeName: 'Tu Lojita (Centro)',
              bookingDate: '2026-11-18',
              slotStartTime: '10:00',
              slotEndTime: '10:30',
              status: 'HOLD',
            ),
          ],
          buyerReviews: const [],
          orderReviewsWritten: const [],
          disputes: const [
            {
              'type': 'DAMAGED_ITEM',
              'status': 'MERCHANT_RESPONDED',
              'description': 'La caja llegó golpeada.',
            },
          ],
          blocks: const [],
          crmOfferEnabled: true,
          crmOfferFeePerCampaign: 0,
        );

        await tester.pumpWidget(
          wrapWithApp(
            const CustomerCrmDetailScreen(customerId: 'cust-1'),
            overrides: [
              crmCustomerDetailProvider(
                'cust-1',
              ).overrideWith((ref) async => richDetail),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Perfil tab: scroll down to Bitácora Interna and verify localized note category badge
        await tester.drag(find.byType(ListView).first, const Offset(0, -800));
        await tester.pumpAndSettle();
        final noteBadgeFinder = find.byType(CrmStatusBadge);
        expect(noteBadgeFinder, findsWidgets);
        expect(
          tester.widget<CrmStatusBadge>(noteBadgeFinder.first).meta.label,
          'Seguimiento',
        );
        expect(find.text('FOLLOW_UP'), findsNothing);

        // Favoritos & Ofertas tab: localized offer status
        await tester.tap(find.text('Favoritos & Ofertas'));
        await tester.pumpAndSettle();
        expect(find.text('Activa'), findsOneWidget);
        expect(find.text('ACTIVE'), findsNothing);

        // Pedidos, Reservas y Cuotas tab: localized order, NONE omitted, installments & HOLD booking
        await tester.ensureVisible(find.text('Pedidos, Reservas y Cuotas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pedidos, Reservas y Cuotas'));
        await tester.pumpAndSettle();
        expect(find.text('Pagado completo'), findsOneWidget);
        expect(find.text('Sin pre-orden'), findsNothing);
        expect(find.text('NONE'), findsNothing);
        expect(find.textContaining('2/3 cuotas pagadas'), findsOneWidget);
        expect(find.text('En espera'), findsOneWidget);
        expect(find.text('FULLY_PAID'), findsNothing);
        expect(find.textContaining('HOLD'), findsNothing);

        // Reputación & Gobernanza tab: localized dispute type & status
        await tester.ensureVisible(find.text('Reputación & Gobernanza'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reputación & Gobernanza'));
        await tester.pumpAndSettle();
        expect(find.text('Producto dañado'), findsOneWidget);
        expect(find.text('Comercio respondió'), findsOneWidget);
        expect(find.textContaining('DAMAGED_ITEM'), findsNothing);
        expect(find.textContaining('MERCHANT_RESPONDED'), findsNothing);
      },
    );

    testWidgets(
      'LTV & RFM educational guides and Slide 3 explain LTV, Recencia, Frecuencia y Monto',
      (tester) async {
        await tester.pumpWidget(
          wrapWithApp(
            const Scaffold(body: CustomersCrmView()),
            overrides: [
              crmSummaryProvider.overrideWith((ref) async => sampleSummary),
              crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('LTV Total (Valor Cliente)'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('crm_ltv_guide_btn')));
        await tester.pumpAndSettle();
        expect(find.text(CrmGuidesCatalog.ltvMetric.title), findsOneWidget);
        expect(find.textContaining('Lifetime Value'), findsOneWidget);
        await tester.ensureVisible(find.text('Entendido'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Entendido'));
        await tester.pumpAndSettle();

        expect(
          CrmGuidesCatalog.rfmSegments.explanation,
          allOf(
            contains('Recencia'),
            contains('Frecuencia'),
            contains('Monto'),
          ),
        );
        expect(
          CrmGuidesCatalog.rfmSegments.bulletPoints.join(' '),
          contains('\$250 USD'),
        );

        // Open Slide 3 of CrmTutorialCarousel
        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: CrmTutorialCarousel(onComplete: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Segmentos RFM, LTV y Alertas'), findsOneWidget);
        expect(find.textContaining('Recencia, Frecuencia y Monto'), findsWidgets);
        expect(find.textContaining('LTV'), findsWidgets);
      },
    );

    testWidgets(
      'All CRM views & modals render without overflow on 320x640 with TextScaler.linear(1.35)',
      (tester) async {
        Future<void> pumpScaled(
          Widget child, {
          List<dynamic> overrides = const [],
        }) async {
          await tester.pumpWidget(
            wrapWithApp(
              MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 640),
                  textScaler: TextScaler.linear(1.35),
                ),
                child: SizedBox(
                  width: 320,
                  height: 640,
                  child: child,
                ),
              ),
              overrides: overrides,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        // 1. CustomersCrmView + CustomerCrmBentoCard
        await pumpScaled(
          const Scaffold(body: CustomersCrmView()),
          overrides: [
            crmSummaryProvider.overrideWith((ref) async => sampleSummary),
            crmCustomersProvider.overrideWith((ref) async => [sampleCustomer]),
          ],
        );

        // 2. CustomerCrmBentoCard standalone
        await pumpScaled(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: CustomerCrmBentoCard(
                customer: sampleCustomer,
                canManageCrm: true,
                onOpenDetail: () {},
              ),
            ),
          ),
        );

        // 3. CustomerCrmDetailScreen across tabs
        await pumpScaled(
          const CustomerCrmDetailScreen(customerId: 'cust-1'),
          overrides: [
            crmCustomerDetailProvider(
              'cust-1',
            ).overrideWith((ref) async => sampleDetail),
          ],
        );
        await tester.tap(find.text('Favoritos & Ofertas'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Pedidos, Reservas y Cuotas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pedidos, Reservas y Cuotas'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Reputación & Gobernanza'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reputación & Gobernanza'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // 4. CrmTutorialCarousel
        await pumpScaled(
          Scaffold(
            body: CrmTutorialCarousel(onComplete: () {}, isModal: true),
          ),
        );

        // 5. CreateTargetedOfferSheet
        const freeConfig = CrmOffersConfig(
          enabled: true,
          feePerCampaign: 0,
          platformPaymentMethods: [],
        );
        await pumpScaled(
          Scaffold(
            body: CreateTargetedOfferSheet(
              companyId: 'comp-1',
              customer: sampleCustomer,
              favoriteItems: [sampleFavorite],
            ),
          ),
          overrides: [
            crmOffersConfigProvider.overrideWith((ref) async => freeConfig),
          ],
        );
      },
    );

    testWidgets(
      'CustomerCrmDetailScreen order cards stretch to full available width on wide screens',
      (tester) async {
        tester.view.physicalSize = const Size(900, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithApp(
            const CustomerCrmDetailScreen(customerId: 'cust-1'),
            overrides: [
              crmCustomerDetailProvider(
                'cust-1',
              ).overrideWith((ref) async => sampleDetail),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Pedidos, Reservas y Cuotas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pedidos, Reservas y Cuotas'));
        await tester.pumpAndSettle();

        final orderCardInkWell = find.ancestor(
          of: find.text('Tu Lojita (Centro)'),
          matching: find.byType(InkWell),
        );
        expect(orderCardInkWell, findsOneWidget);
        final cardSize = tester.getSize(orderCardInkWell);
        expect(cardSize.width, greaterThan(750));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
