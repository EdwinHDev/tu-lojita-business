import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/notification.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/orders/data/repositories/order_repository_impl.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_dispute.dart';
import 'package:tu_lojita_business/features/orders/domain/repositories/order_repository.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/dispute_providers.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/orders_provider.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/order_details_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/screens/order_list_screen.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_customer_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_detail_dialogs.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_detail_header.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_detail_helpers.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_financial_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_installments_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_items_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_payments_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_urgent_action_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/refund_required_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/orders_bento_shimmer.dart';
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
  @override
  Future<List<AppNotification>> build() async => const [];

  @override
  Future<void> loadNotifications() async {
    state = const AsyncData([]);
  }

  @override
  Future<void> markOrderNotificationsAsRead(
    String orderId, {
    bool onlyChat = false,
    bool isSupportChat = false,
  }) async {}
}

class _RecordedQuery {
  final String storeId;
  final int limit;
  final int offset;
  final String? status;
  final bool? hasDispute;
  final bool? hasPendingPayment;
  final String? search;

  const _RecordedQuery({
    required this.storeId,
    required this.limit,
    required this.offset,
    this.status,
    this.hasDispute,
    this.hasPendingPayment,
    this.search,
  });
}

class _FakeOrderRepository implements OrderRepository {
  final List<Order> orders;
  final Completer<List<Order>>? blockingCompleter;
  final List<_RecordedQuery> queries = [];

  _FakeOrderRepository({
    this.orders = const [],
    this.blockingCompleter,
  });

  @override
  Future<List<Order>> getOrdersPaginated(
    String storeId,
    int limit,
    int offset, {
    String? status,
    bool? hasDispute,
    bool? hasPendingPayment,
    String? search,
  }) async {
    queries.add(
      _RecordedQuery(
        storeId: storeId,
        limit: limit,
        offset: offset,
        status: status,
        hasDispute: hasDispute,
        hasPendingPayment: hasPendingPayment,
        search: search,
      ),
    );
    if (blockingCompleter != null) {
      return blockingCompleter!.future;
    }
    return orders.where((o) {
      if (status != null && o.status != status) return false;
      if (hasPendingPayment == true &&
          !o.payments.any((p) => p.status == 'WAITING_VERIFICATION')) {
        return false;
      }
      if (hasDispute == true && !o.hasActiveDispute) return false;
      return true;
    }).toList();
  }

  @override
  Future<Order> getOrderById(String orderId) async =>
      orders.firstWhere((o) => o.id == orderId, orElse: () => orders.first);

  @override
  Future<List<Installment>> getStoreInstallments(String storeId) async => [];

  @override
  Future<List<Installment>> getStoreReceivables(String storeId) async => [];

  @override
  Future<Map<String, dynamic>> getOrderStatement(String orderId) async => {};

  @override
  Future<Order> markPreOrderStockArrived(String orderId) async => orders.first;

  @override
  Future<Map<String, dynamic>> registerManualPayment(
    String orderId,
    double amount,
    String paymentMethod, {
    String? reference,
    String? notes,
  }) async =>
      {};

  @override
  Future<Order> updateOrderStatus(String orderId, String status,
          {String? reason}) async =>
      orders.first;

  @override
  Future<void> verifyExtension(String installmentId, String status,
      {String? merchantComment}) async {}

  @override
  Future<Order> verifyPayment(String paymentId, String status, String orderId,
          {String? rejectionReason, String? receiptImage}) async =>
      orders.first;
}

class _CapturingHttpAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      jsonEncode({'items': []}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Order _buildSampleOrder({
  String id = 'ord-99001122-aaaa',
  String status = 'PARTIALLY_PAID',
  String? preOrderStatus,
  List<Map<String, dynamic>>? payments,
  List<Map<String, dynamic>>? installments,
  bool includeCustomerPii = true,
  bool includeCommissions = true,
  double feeAmount = 5.0,
}) {
  return Order.fromJson({
    'id': id,
    'storeId': 'store-1',
    'storeName': 'Tu Lojita Centro',
    'status': status,
    'totalAmount': 100.0,
    'feeAmount': feeAmount,
    'finalAmount': 100.0 + feeAmount,
    'balance': status == 'FULLY_PAID' ? 0.0 : 50.0,
    'platformCommissionRate': includeCommissions ? 5.0 : 0.0,
    'platformCommissionAmount': includeCommissions ? 5.25 : 0.0,
    'isPartialPayment': true,
    'preOrderStatus': preOrderStatus,
    'createdAt': '2026-11-11T15:30:00.000Z',
    'user': includeCustomerPii
        ? {
            'id': 'cust-1',
            'firstName': 'Camila',
            'lastName': 'Rojas',
            'email': 'camila@cliente.com',
            'phone': '04125550199',
            'address': 'Av. Bolívar con Calle 12, Casa 4',
          }
        : {
            'id': 'cust-1',
            'firstName': 'Camila',
            'lastName': 'Rojas',
          },
    'orderItems': [
      {
        'id': 'oi-1',
        'quantity': 1,
        'price': 100.0,
        'basePrice': 100.0,
        'commissionRate': includeCommissions ? 5.0 : 0.0,
        'commissionAmount': includeCommissions ? 5.0 : 0.0,
        'variantLabel': 'Talla M · Azul',
        'selectedOptions': {
          'grp-1': ['opt-1'],
        },
        'item': {
          'id': 'item-1',
          'title': 'Chaqueta Impermeable Premium',
          'price': 100.0,
          'images': [],
          'commissionRate': includeCommissions ? 5.0 : 0.0,
          'optionGroups': [
            {
              'id': 'grp-1',
              'name': 'Extras',
              'options': [
                {'id': 'opt-1', 'name': 'Empaque de Regalo', 'price': 4.0},
              ],
            },
          ],
        },
      },
    ],
    'installments': installments ??
        [
          {
            'id': 'inst-1',
            'amount': 52.5,
            'paidAmount': 52.5,
            'lateFeeApplied': 0.0,
            'dueDate': '2026-11-05T12:00:00.000Z',
            'status': 'PAID',
            'extensionStatus': 'NONE',
          },
          {
            'id': 'inst-2',
            'amount': 52.5,
            'paidAmount': 0.0,
            'lateFeeApplied': 0.0,
            'dueDate': '2026-11-20T12:00:00.000Z',
            'status': 'PENDING',
            'extensionStatus': 'PENDING',
            'extensionRequestedDays': 5,
            'extensionReason': 'Esperando cobro de quincena',
          },
        ],
    'payments': payments ??
        [
          {
            'id': 'pay-1',
            'amount': 52.5,
            'paymentMethod': 'BINANCE',
            'reference': 'BN-884422',
            'status': 'WAITING_VERIFICATION',
            'createdAt': '2026-11-11T16:00:00.000Z',
          },
        ],
  });
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    await initializeDateFormatting('es');
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
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

  const verifyOnlyCollab = User(
    id: 'collab-verify',
    email: 'verify@tulojita.com',
    firstName: 'Ana',
    lastName: 'Verificadora',
    role: 'COLLABORATOR',
    isCollaborator: true,
    company: company,
    allowedBranchIds: ['store-1'],
    permissions: [
      'orders:view',
      'installments:approve_payment',
    ],
  );

  const rejectOnlyCollab = User(
    id: 'collab-reject',
    email: 'reject@tulojita.com',
    firstName: 'Luis',
    lastName: 'Control',
    role: 'COLLABORATOR',
    isCollaborator: true,
    company: company,
    allowedBranchIds: ['store-1'],
    permissions: [
      'orders:view',
      'orders:view_customer_data',
      'installments:reject_payment',
    ],
  );

  const activeRate = ExchangeRateConfig(
    enabled: true,
    rate: 50.0,
    symbol: 'Bs.',
  );

  const disabledRate = ExchangeRateConfig(
    enabled: false,
    rate: 0.0,
    symbol: 'Bs.',
  );

  Widget wrapTestApp({
    required Widget home,
    User user = ownerUser,
    ExchangeRateConfig rateConfig = activeRate,
    OrderRepository? repo,
    Order? detailOrderOverride,
    bool neverCompleteOrderById = false,
    double width = 390,
    double textScale = 1.0,
  }) {
    final effectiveRepo = repo ?? _FakeOrderRepository();
    return ProviderScope(
      key: ValueKey('${user.id}_${detailOrderOverride?.id ?? 'none'}_${rateConfig.rate}_${width}_$textScale'),
      overrides: [
        authProvider.overrideWith(() => _FakeAuthNotifier(user)),
        exchangeRateProvider
            .overrideWith(() => _FakeExchangeRateNotifier(rateConfig)),
        notificationsProvider
            .overrideWith(() => _FakeNotificationsNotifier()),
        ordersRepositoryProvider.overrideWithValue(effectiveRepo),
        unreadBusinessDisputeOrderIdsProvider.overrideWithValue(<String>{}),
        activeStoreDisputeProvider.overrideWith((ref, id) => null),
        storeDisputesByOrderProvider
            .overrideWith((ref, id) async => <OrderDispute>[]),
        if (neverCompleteOrderById)
          orderByIdProvider
              .overrideWith((ref, id) => Completer<Order>().future)
        else if (detailOrderOverride != null)
          orderByIdProvider.overrideWith((ref, id) async => detailOrderOverride),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(width, 844),
              textScaler: TextScaler.linear(textScale),
            ),
            child: SizedBox(width: width, child: home),
          ),
        ),
      ),
    );
  }

  group('Permissions, OrderFilter & Repository Query Params', () {
    test('User getters distinguish reject/verify installments and finances', () {
      expect(ownerUser.canApproveInstallments, isTrue);
      expect(ownerUser.canRejectInstallments, isTrue);
      expect(ownerUser.canViewSensitiveFinances, isTrue);
      expect(ownerUser.canViewSensitiveCustomerData, isTrue);

      expect(verifyOnlyCollab.canApproveInstallments, isTrue);
      expect(verifyOnlyCollab.canRejectInstallments, isFalse);
      expect(verifyOnlyCollab.canViewInstallments, isTrue);
      expect(verifyOnlyCollab.canViewSensitiveFinances, isFalse);
      expect(verifyOnlyCollab.canViewSensitiveCustomerData, isFalse);
      expect(verifyOnlyCollab.canProcessOrders, isFalse);

      expect(rejectOnlyCollab.canApproveInstallments, isFalse);
      expect(rejectOnlyCollab.canRejectInstallments, isTrue);
      expect(rejectOnlyCollab.canViewInstallments, isTrue);
      expect(rejectOnlyCollab.canViewSensitiveCustomerData, isTrue);
      expect(rejectOnlyCollab.canViewSensitiveFinances, isFalse);

      const financeCollab = User(
        id: 'collab-fin',
        email: 'fin@tulojita.com',
        firstName: 'Finanzas',
        lastName: 'Control',
        role: 'COLLABORATOR',
        isCollaborator: true,
        permissions: ['metrics:view_financial'],
      );
      expect(financeCollab.canViewSensitiveFinances, isTrue);
    });

    test('OrderDetailHelpers.formatPaymentMethod normalizes payment codes', () {
      expect(OrderDetailHelpers.formatPaymentMethod('PAGO_MOVIL'), 'Pago Móvil');
      expect(OrderDetailHelpers.formatPaymentMethod('TRANSFER'), 'Transferencia');
      expect(OrderDetailHelpers.formatPaymentMethod('BANK_TRANSFER'), 'Transferencia');
      expect(OrderDetailHelpers.formatPaymentMethod('BINANCE'), 'Binance Pay');
      expect(OrderDetailHelpers.formatPaymentMethod('ZELLE'), 'Zelle');
      expect(OrderDetailHelpers.formatPaymentMethod('CASH_USD'), 'Efectivo USD');
      expect(OrderDetailHelpers.formatPaymentMethod('CASH_BS'), 'Efectivo Bs.');
    });

    test('buildOrderFilter & OrderRepositoryImpl forward hasPendingPayment and search',
        () async {
      final f1 = buildOrderFilter(
        storeId: 'store-1',
        hasPendingPayment: true,
        search: 'BN-8844',
      );
      final f2 = buildOrderFilter(
        storeId: 'store-1',
        hasPendingPayment: true,
        search: 'BN-8844',
      );
      expect(f1, equals(f2));

      final adapter = _CapturingHttpAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.tulojita.com/api/v1'));
      dio.httpClientAdapter = adapter;
      final repo = OrderRepositoryImpl(dio: dio);

      await repo.getOrdersPaginated(
        'store-1',
        15,
        0,
        hasPendingPayment: true,
        search: '  BN-8844  ',
      );

      expect(adapter.lastOptions?.path, '/order');
      expect(adapter.lastOptions?.queryParameters, {
        'storeId': 'store-1',
        'limit': 15,
        'offset': 0,
        'hasPendingPayment': true,
        'search': 'BN-8844',
      });
    });
  });

  group('OrderListScreen & OrderCard Bento UX', () {
    testWidgets('shows OrderListBentoShimmer while initial orders load',
        (tester) async {
      final blockingRepo =
          _FakeOrderRepository(blockingCompleter: Completer<List<Order>>());
      await tester.pumpWidget(
        wrapTestApp(
          home: const OrderListScreen(storeId: 'store-1'),
          repo: blockingRepo,
        ),
      );
      await tester.pump();
      expect(find.byType(OrderListBentoShimmer), findsOneWidget);
    });

    testWidgets(
        'displays Tasa BCV pill, Por verificar tab, server search debounce, DualPriceText and phone masking',
        (tester) async {
      final pendingOrder = _buildSampleOrder(id: 'ord-waiting-1');
      final paidOrder = _buildSampleOrder(
        id: 'ord-paid-2',
        status: 'FULLY_PAID',
        feeAmount: 0.0,
        payments: [
          {
            'id': 'pay-paid',
            'amount': 100.0,
            'paymentMethod': 'TRANSFER',
            'reference': 'TR-1122',
            'status': 'APPROVED',
            'createdAt': '2026-11-11T14:00:00.000Z',
          },
        ],
        installments: [],
      );
      final fakeRepo = _FakeOrderRepository(orders: [pendingOrder, paidOrder]);

      await tester.pumpWidget(
        wrapTestApp(
          home: const OrderListScreen(storeId: 'store-1'),
          repo: fakeRepo,
          user: ownerUser,
          rateConfig: activeRate,
        ),
      );
      await tester.pumpAndSettle();

      // Header & BCV pill + Tabs
      expect(find.textContaining('Tasa BCV:'), findsOneWidget);
      expect(find.text('Por verificar'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);

      // Urgency chips & DualPriceText Bs reference on OrderCard
      expect(find.text('Comprobante en revisión'), findsWidgets);
      expect(find.text('Prórroga pendiente'), findsWidgets);
      expect(find.textContaining('Bs.'), findsWidgets);
      expect(find.text('Binance Pay'), findsOneWidget);
      expect(find.text('Transferencia'), findsOneWidget);

      // Switch to Por verificar tab -> sends hasPendingPayment: true
      await tester.tap(find.text('Por verificar'));
      await tester.pumpAndSettle();
      expect(
        fakeRepo.queries.any((q) => q.hasPendingPayment == true),
        isTrue,
      );

      // Enter search text -> triggers 380ms debounce server query
      await tester.enterText(find.byType(TextField), 'BN-884422');
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pumpAndSettle();
      expect(
        fakeRepo.queries.any((q) => q.search == 'BN-884422'),
        isTrue,
      );
    });

    testWidgets(
        'OrderCard masks phone for restricted user, hides Bs when disabled, and has zero overflow at 320px @ 1.35x',
        (tester) async {
      final order = _buildSampleOrder();

      await tester.pumpWidget(
        wrapTestApp(
          width: 320,
          textScale: 1.35,
          rateConfig: disabledRate,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: OrderCard(
                order: order,
                canViewCustomerData: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('• Contacto protegido'), findsOneWidget);
      expect(find.text('04125550199'), findsNothing);
      // With disabled rate, only $ prices render without ~ Bs.
      expect(find.textContaining('~ Bs.'), findsNothing);
    });
  });

  group('OrderDetailsScreen, Urgent Action Card, Privacy & RBAC', () {
    testWidgets('shows OrderDetailsBentoShimmer while fetching order by ID',
        (tester) async {
      await tester.pumpWidget(
        wrapTestApp(
          home: const OrderDetailsScreen(orderId: 'ord-1', storeId: 'store-1'),
          neverCompleteOrderById: true,
        ),
      );
      await tester.pump();
      expect(find.byType(OrderDetailsBentoShimmer), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'owner sees Acción Requerida, DualPriceText on all cards, commissions, and Restringir',
        (tester) async {
      final order = _buildSampleOrder(preOrderStatus: 'AWAITING_STOCK');

      await tester.pumpWidget(
        wrapTestApp(
          user: ownerUser,
          rateConfig: activeRate,
          detailOrderOverride: order,
          home: OrderDetailsScreen(
            order: order,
            orderId: order.id,
            storeId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Urgent action card rendered immediately beneath status card
      expect(find.byType(OrderUrgentActionCard), findsOneWidget);
      expect(find.text('Acción Requerida'), findsOneWidget);
      expect(find.text('1 comprobante por verificar'), findsOneWidget);
      expect(find.text('Solicitud de prórroga pendiente (Cuota #2)'), findsOneWidget);
      expect(find.text('Preventa esperando llegada de stock'), findsOneWidget);

      // Customer PII & Restringir visible for owner
      expect(find.text('Restringir'), findsOneWidget);
      expect(find.text('camila@cliente.com'), findsOneWidget);
      expect(find.text('04125550199'), findsOneWidget);

      // Commission breakdown visible for owner
      expect(find.textContaining('Comisión Plataforma'), findsOneWidget);
      expect(find.text('Tu Ingreso Neto Tienda'), findsOneWidget);

      // All action buttons visible for owner
      expect(find.text('Aprobar Pago'), findsOneWidget);
      expect(find.text('Rechazar Pago'), findsOneWidget);
      expect(find.text('Aprobar Prórroga'), findsOneWidget);
      expect(find.text('Stock Recibido en Tienda'), findsOneWidget);

      // Multiple DualPriceText widgets render ~ Bs.
      expect(find.byType(DualPriceText), findsWidgets);
      expect(find.textContaining('Bs.'), findsWidgets);

      // Tapping 'Revisar ahora' scrolls smoothly to target section without error
      await tester.tap(find.text('Revisar ahora').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Clean settled order hides OrderUrgentActionCard
      final cleanOrder = _buildSampleOrder(
        id: 'ord-settled-99',
        status: 'FULLY_PAID',
        payments: [
          {
            'id': 'pay-ok',
            'amount': 105.0,
            'paymentMethod': 'TRANSFER',
            'status': 'APPROVED',
            'createdAt': '2026-11-11T16:00:00.000Z',
          },
        ],
        installments: [],
      );
      await tester.pumpWidget(
        wrapTestApp(
          user: ownerUser,
          rateConfig: activeRate,
          detailOrderOverride: cleanOrder,
          home: OrderDetailsScreen(
            key: const ValueKey('clean-order-details'),
            order: cleanOrder,
            orderId: cleanOrder.id,
            storeId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acción Requerida'), findsNothing);
    });

    testWidgets(
        'collaborator privacy & granular RBAC gating across cards and dialogs',
        (tester) async {
      final order = _buildSampleOrder(preOrderStatus: 'AWAITING_STOCK');

      // Collaborator 1: verify_payment only, no view_customer_data, no finances
      await tester.pumpWidget(
        wrapTestApp(
          user: verifyOnlyCollab,
          rateConfig: activeRate,
          detailOrderOverride: order,
          home: OrderDetailsScreen(
            order: order,
            orderId: order.id,
            storeId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Masks email, phone, address & hides Restringir
      expect(find.text('Correo protegido'), findsOneWidget);
      expect(find.text('Contacto protegido'), findsOneWidget);
      expect(find.text('Dirección protegida'), findsOneWidget);
      expect(find.text('camila@cliente.com'), findsNothing);
      expect(find.text('04125550199'), findsNothing);
      expect(find.text('Restringir'), findsNothing);

      // Hides commission & net payout across items & financial cards
      expect(find.textContaining('Comisión Plataforma'), findsNothing);
      expect(find.text('Tu Ingreso Neto Tienda'), findsNothing);
      expect(find.textContaining('Comisión:'), findsNothing);
      expect(find.textContaining('Neto:'), findsNothing);

      // Approve allowed, Reject hidden, Pre-order stock arrival hidden (needs orders:process)
      expect(find.text('Aprobar Pago'), findsOneWidget);
      expect(find.text('Rechazar Pago'), findsNothing);
      expect(find.text('Aprobar Prórroga'), findsOneWidget);
      expect(find.text('Stock Recibido en Tienda'), findsNothing);

      // Collaborator 2: reject_payment + view_customer_data (still cannot Restrict customer)
      await tester.pumpWidget(
        wrapTestApp(
          user: rejectOnlyCollab,
          rateConfig: activeRate,
          detailOrderOverride: order,
          home: OrderDetailsScreen(
            key: const ValueKey('reject-only-collab'),
            order: order,
            orderId: order.id,
            storeId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Customer data shown, but Restringir STILL hidden for collaborators!
      expect(find.text('camila@cliente.com'), findsOneWidget);
      expect(find.text('Restringir'), findsNothing);

      // Reject allowed, Approve hidden, Extension actions hidden
      expect(find.text('Rechazar Pago'), findsOneWidget);
      expect(find.text('Aprobar Pago'), findsNothing);
      expect(find.text('Aprobar Prórroga'), findsNothing);
      expect(
        find.text('Pendiente de aprobación por encargado autorizado'),
        findsOneWidget,
      );
    });

    testWidgets(
        'RefundRequiredCard & dialogs respect canProcessOrders, DualPriceText and allowRestrictCustomer',
        (tester) async {
      final cancelledOrder = _buildSampleOrder(
        status: 'CANCELLED',
        payments: [
          {
            'id': 'pay-ref-1',
            'amount': 52.5,
            'paymentMethod': 'PAGO_MOVIL',
            'reference': 'PM-4433',
            'status': 'WAITING_VERIFICATION',
            'createdAt': '2026-11-11T16:00:00.000Z',
          },
        ],
        installments: [],
      );

      // Collaborator without orders:process sees calm notice instead of refund action buttons
      await tester.pumpWidget(
        wrapTestApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RefundRequiredCard(
                order: cancelledOrder,
                payment: cancelledOrder.payments.first,
                canProcessOrders: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DualPriceText), findsOneWidget);
      expect(find.text('Registrar Reembolso'), findsNothing);
      expect(find.text('Declarar pago no recibido'), findsNothing);
      expect(
        find.text('Requiere permiso de gestión de pedidos para registrar reembolsos'),
        findsOneWidget,
      );

      // Confirm approve payment dialog shows DualPriceText
      late BuildContext dialogHostContext;
      await tester.pumpWidget(
        wrapTestApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                dialogHostContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      unawaited(
        OrderDetailDialogs.showConfirmApprovePayment(
          dialogHostContext,
          payment: cancelledOrder.payments.first,
          order: cancelledOrder,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('¿Aprobar Comprobante?'), findsOneWidget);
      expect(find.byType(DualPriceText), findsWidgets);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Reject payment sheet hides 'Restringir cliente también' when allowRestrictCustomer: false
      unawaited(
        OrderDetailDialogs.showRejectPaymentBottomSheet(
          dialogHostContext,
          payment: cancelledOrder.payments.first,
          allowRestrictCustomer: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rechazar Comprobante'), findsOneWidget);
      expect(find.text('Restringir cliente también'), findsNothing);
    });

    testWidgets(
        'renders OrderDetailsScreen & all subcards without overflow at 320px width and 1.35x textScale',
        (tester) async {
      final order = _buildSampleOrder(preOrderStatus: 'AWAITING_STOCK');

      await tester.pumpWidget(
        wrapTestApp(
          width: 320,
          textScale: 1.35,
          user: ownerUser,
          rateConfig: activeRate,
          detailOrderOverride: order,
          home: OrderDetailsScreen(
            order: order,
            orderId: order.id,
            storeId: 'store-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(OrderStatusCard), findsOneWidget);
      expect(find.byType(OrderUrgentActionCard), findsOneWidget);
      expect(find.byType(OrderCustomerCard), findsOneWidget);
      expect(find.byType(OrderItemsCard), findsOneWidget);
      expect(find.byType(OrderFinancialCard), findsOneWidget);
      expect(find.byType(OrderInstallmentsCard), findsOneWidget);
      expect(find.byType(OrderPaymentsCard), findsOneWidget);
    });
  });
}
