import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/dispute_providers.dart';
import 'package:tu_lojita_business/features/orders/presentation/utils/order_pdf_helpers.dart';
import 'package:tu_lojita_business/features/orders/presentation/utils/order_sales_control_downloader.dart';
import 'package:tu_lojita_business/features/orders/presentation/utils/order_sales_control_pdf_generator.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_detail_header.dart';

class _FakeExchangeRateNotifier extends ExchangeRateNotifier {
  @override
  Future<ExchangeRateConfig> build() async {
    return const ExchangeRateConfig(enabled: true, rate: 52.5, symbol: 'Bs.');
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const Authenticated(
        User(
          id: 'owner-1',
          email: 'owner@tulojita.com',
          firstName: 'Tienda',
          lastName: 'Demo',
          role: 'COMPANY',
          hasCompany: true,
        ),
      );
}

Order _buildCompletedCashOrder() {
  return Order.fromJson({
    'id': 'a1b2c3d4-5678-90ab-cdef-1234567890ab',
    'status': 'FULLY_PAID',
    'totalAmount': '105.00',
    'feeAmount': '0.00',
    'platformCommissionRate': '5.00',
    'platformCommissionAmount': '5.00',
    'finalAmount': '105.00',
    'balance': '0.00',
    'isPartialPayment': false,
    'isFullyPaid': true,
    'totalPaidAmount': '105.00',
    'remainingBalance': '0.00',
    'createdAt': '2026-11-12T15:30:00.000Z',
    'storeId': 'st-99887766',
    'storeName': 'Boutique El Valle',
    'user': {
      'id': 'usr-1',
      'firstName': 'María',
      'lastName': 'González',
      'email': 'maria.gonzalez@example.com',
      'phone': '04141234567',
      'address': 'Av. Bolívar, Edif. Sol, Piso 2',
      'identification': 'V-19876543',
    },
    'orderItems': [
      {
        'id': 'oi-1',
        'title': 'Camisa Oxford',
        'basePrice': '50.00',
        'commissionRate': '5.00',
        'commissionAmount': '2.50',
        'price': '52.50',
        'quantity': 2,
        'variantId': 'var-1',
        'variantLabel': 'Azul / Talla M',
        'selectedOptions': {
          'grp-1': ['opt-1', 'opt-1'],
        },
        'item': {
          'id': 'it-1',
          'title': 'Camisa Oxford',
          'price': 52.5,
          'images': [],
          'customizationGroups': [
            {
              'id': 'grp-1',
              'name': 'Bordado',
              'maxSelect': 2,
              'minSelect': 0,
              'options': [
                {'id': 'opt-1', 'name': 'Iniciales Pecho', 'price': 0},
              ],
            }
          ],
        },
      }
    ],
    'payments': [
      {
        'id': 'pay-1',
        'amount': '105.00',
        'currency': 'USD',
        'status': 'APPROVED',
        'paymentMethod': 'ZELLE',
        'reference': 'ZLL-884412',
        'createdAt': '2026-11-12T15:35:00.000Z',
      }
    ],
    'installments': [],
  });
}

Order _buildCompletedInstallmentPreOrderWithSlots() {
  return Order.fromJson({
    'id': 'f9e8d7c6-1122-3344-5566-77889900aabb',
    'status': 'FULLY_PAID',
    'totalAmount': '210.00',
    'feeAmount': '15.00',
    'platformCommissionRate': '5.00',
    'platformCommissionAmount': '10.00',
    'finalAmount': '225.00',
    'balance': '0.00',
    'isPartialPayment': true,
    'isFullyPaid': true,
    'totalPaidAmount': '230.00',
    'remainingBalance': '0.00',
    'preOrderStatus': 'FULFILLED',
    'settlementDeadline': '2026-11-10T22:00:00.000Z',
    'createdAt': '2026-11-01T14:00:00.000Z',
    'storeId': 'st-11223344',
    'storeName': 'Estudio & Taller Creativo',
    'user': {
      'id': 'usr-2',
      'firstName': 'Carlos',
      'lastName': 'Mendoza',
      'email': 'carlos@example.com',
      'phone': '04129998877',
      'address': 'Calle Miranda #45',
    },
    'orderItems': [
      {
        'id': 'oi-2',
        'title': 'Paquete Diseño + Sesión',
        'basePrice': '200.00',
        'commissionRate': '5.00',
        'commissionAmount': '10.00',
        'price': '210.00',
        'quantity': 1,
        'variantLabel': 'Dorado',
        'selectedOptions': const <String, List<String>>{},
      }
    ],
    'payments': [
      {
        'id': 'pay-i1',
        'amount': '112.50',
        'currency': 'USD',
        'status': 'APPROVED',
        'paymentMethod': 'PAGO_MOVIL',
        'reference': '00987654',
        'installmentIndex': 1,
        'createdAt': '2026-11-01T14:05:00.000Z',
      },
      {
        'id': 'pay-i2',
        'amount': '117.50',
        'currency': 'VES',
        'status': 'APPROVED',
        'paymentMethod': 'TRANSFER',
        'reference': 'TRF-445566',
        'installmentIndex': 2,
        'createdAt': '2026-11-09T18:10:00.000Z',
      },
    ],
    'installments': [
      {
        'id': 'inst-1',
        'amount': '112.50',
        'paidAmount': '112.50',
        'lateFeeApplied': '0.00',
        'dueDate': '2026-11-01T23:59:59.000Z',
        'paymentDate': '2026-11-01T14:05:00.000Z',
        'status': 'PAID',
      },
      {
        'id': 'inst-2',
        'amount': '112.50',
        'paidAmount': '117.50',
        'lateFeeApplied': '5.00',
        'dueDate': '2026-11-08T23:59:59.000Z',
        'paymentDate': '2026-11-09T18:10:00.000Z',
        'status': 'PAID',
      },
    ],
    'slotBookings': [
      {
        'bookingDate': '2026-11-12',
        'status': 'CONFIRMED',
        'slot': {
          'label': 'Sesión Mañana',
          'startTime': '09:00',
          'endTime': '10:30',
        },
      }
    ],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:3000/api/v1');

  group('OrderPdfHelpers & Formatting', () {
    test('isOrderCompleted returns true only for FULLY_PAID or isFullyPaid', () {
      expect(OrderPdfHelpers.isOrderCompleted(_buildCompletedCashOrder()), isTrue);
      expect(
        OrderPdfHelpers.isOrderCompleted(
          Order.fromJson({
            'id': 'ord-p',
            'status': 'PENDING',
            'totalAmount': 20,
            'finalAmount': 20,
            'balance': 20,
            'isFullyPaid': false,
            'createdAt': '2026-11-12T10:00:00.000Z',
            'orderItems': const [],
          }),
        ),
        isFalse,
      );
      expect(
        OrderPdfHelpers.isOrderCompleted(
          Order.fromJson({
            'id': 'ord-part',
            'status': 'PARTIALLY_PAID',
            'totalAmount': 20,
            'finalAmount': 20,
            'balance': 10,
            'isFullyPaid': false,
            'createdAt': '2026-11-12T10:00:00.000Z',
            'orderItems': const [],
          }),
        ),
        isFalse,
      );
    });

    test('VariantColorParser and OrderPdfCustomizationHelper format variants and options', () {
      expect(VariantColorParser.parseColor('Azul / Talla M'), isNotNull);
      expect(VariantColorParser.parseColor('#4F46E5'), const Color(0xFF4F46E5));

      final formatted = OrderPdfCustomizationHelper.formatSingleLine(
        selectedOptions: {
          'g1': ['o1', 'o1', 'o2'],
        },
        availableGroups: const [
          CustomizationGroup(
            id: 'g1',
            name: 'Salsas',
            maxSelect: 3,
            minSelect: 0,
            options: [
              CustomizationOption(id: 'o1', name: 'Ajo', price: 0),
              CustomizationOption(id: 'o2', name: 'Tártara', price: 0),
            ],
          ),
        ],
      );
      expect(formatted, 'Salsas: Ajo x2, Tártara');
      expect(
        OrderSalesControlDownloader.buildFileName('a1b2c3d4-5678-90ab'),
        'control_venta_A1B2C3D4.pdf',
      );
    });
  });

  group('OrderSalesControlPdfGenerator', () {
    test('generates valid PDF bytes for completed cash order with dual BCV rate', () async {
      final order = _buildCompletedCashOrder();
      final bytes = await OrderSalesControlPdfGenerator.generate(
        order,
        exchangeRate: const ExchangeRateConfig(enabled: true, rate: 52.5, symbol: 'Bs.'),
        storeAddress: 'Av. Principal #10, Upata',
        storePhone: '04241112233',
        exportedBy: 'Edwin Hernández',
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('generates valid PDF bytes for installment order with late fees, pre-order and slots', () async {
      final order = _buildCompletedInstallmentPreOrderWithSlots();
      final bytes = await OrderSalesControlPdfGenerator.generate(
        order,
        exchangeRate: const ExchangeRateConfig(enabled: true, rate: 50.0, symbol: 'Bs.'),
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('generates valid PDF bytes with RBAC masking flags disabled', () async {
      final order = _buildCompletedInstallmentPreOrderWithSlots();
      final bytes = await OrderSalesControlPdfGenerator.generate(
        order,
        canViewSensitiveFinances: false,
        canViewSensitiveCustomerData: false,
        exportedBy: 'Cajero Turno B',
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('OrderStatusCard & OrderDetailAppBar PDF Visibility Widgets', () {
    testWidgets('shows download and share PDF actions when order is FULLY_PAID', (tester) async {
      final completedOrder = _buildCompletedCashOrder();
      var downloadTapped = false;
      var shareTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_FakeAuthNotifier.new),
            exchangeRateProvider.overrideWith(_FakeExchangeRateNotifier.new),
            storeDisputesByOrderProvider(completedOrder.id)
                .overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: OrderDetailAppBar(
                order: completedOrder,
                onDownloadPdf: () => downloadTapped = true,
                onSharePdf: () => shareTapped = true,
              ),
              body: SingleChildScrollView(
                child: OrderStatusCard(
                  order: completedOrder,
                  onDownloadPdf: () => downloadTapped = true,
                  onSharePdf: () => shareTapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Descargar Control de Venta (PDF)'), findsOneWidget);
      expect(find.text('Compartir'), findsOneWidget);
      expect(find.byTooltip('Descargar Control de Venta (PDF)'), findsOneWidget);

      await tester.tap(find.text('Descargar Control de Venta (PDF)'));
      await tester.pump();
      expect(downloadTapped, isTrue);

      await tester.tap(find.text('Compartir'));
      await tester.pump();
      expect(shareTapped, isTrue);
    });

    testWidgets('hides PDF actions when order is PENDING, PARTIALLY_PAID or CANCELLED', (tester) async {
      for (final status in ['PENDING', 'PARTIALLY_PAID', 'CANCELLED']) {
        final incompleteOrder = Order.fromJson({
          'id': 'ord-$status-1',
          'status': status,
          'totalAmount': 40,
          'finalAmount': 40,
          'balance': 20,
          'isFullyPaid': false,
          'createdAt': '2026-11-12T10:00:00.000Z',
          'orderItems': const [],
        });

        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(status),
            overrides: [
              authProvider.overrideWith(_FakeAuthNotifier.new),
              exchangeRateProvider.overrideWith(_FakeExchangeRateNotifier.new),
              storeDisputesByOrderProvider(incompleteOrder.id)
                  .overrideWith((ref) async => const []),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: OrderDetailAppBar(
                  order: incompleteOrder,
                  onDownloadPdf: () {},
                  onSharePdf: () {},
                ),
                body: SingleChildScrollView(
                  child: OrderStatusCard(
                    order: incompleteOrder,
                    onDownloadPdf: () {},
                    onSharePdf: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Descargar Control de Venta (PDF)'), findsNothing,
            reason: 'Status $status should not show PDF download button');
        expect(find.text('Compartir'), findsNothing);
        expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      }
    });
  });

  group('Historical Exchange Rate & Tu Lojita Empresa Branding', () {
    test('ExchangeRateConfig.resolveForOrder prioritizes historical rate and respects disabled config', () {
      const liveConfig = ExchangeRateConfig(enabled: true, rate: 55.0, symbol: 'Bs.');
      final historical = ExchangeRateConfig.resolveForOrder(liveConfig, 40.0);
      expect(historical, isNotNull);
      expect(historical!.enabled, isTrue);
      expect(historical.rate, 40.0);
      expect(historical.toBolivares(100), 4000.0);

      final fallback = ExchangeRateConfig.resolveForOrder(liveConfig, null);
      expect(fallback?.rate, 55.0);

      final disabled = ExchangeRateConfig.resolveForOrder(
        const ExchangeRateConfig(enabled: false, rate: 55.0),
        40.0,
      );
      expect(disabled?.enabled, isFalse);
    });

    test('Order.fromJson and Payment.fromJson parse historical exchangeRate', () {
      final order = Order.fromJson({
        'id': 'ord-hist-1',
        'status': 'FULLY_PAID',
        'totalAmount': '100.00',
        'finalAmount': '100.00',
        'balance': '0.00',
        'exchangeRate': '40.0000',
        'createdAt': '2026-10-01T10:00:00.000Z',
        'orderItems': const [],
        'payments': [
          {
            'id': 'pay-hist-1',
            'amount': '50.00',
            'exchangeRate': '42.5000',
            'currency': 'USD',
            'status': 'APPROVED',
            'paymentMethod': 'PAGO_MOVIL',
            'createdAt': '2026-10-02T10:00:00.000Z',
          },
        ],
      });

      expect(order.exchangeRate, 40.0);
      expect(order.payments.first.exchangeRate, 42.5);
    });

    testWidgets('DualPriceText uses customRate over live exchangeRateProvider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider.overrideWith(_FakeExchangeRateNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DualPriceText(
                amountInUsd: 100.0,
                customRate: 40.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$ 100,00'), findsOneWidget);
      expect(find.text('~ Bs. 4.000,00'), findsOneWidget);
      expect(find.text('~ Bs. 5.250,00'), findsNothing);
    });

    test('OrderSalesControlPdfGenerator supports historical order and payment exchange rates', () async {
      final order = Order.fromJson({
        'id': 'a1b2c3d4-5678-90ab-cdef-1234567890ab',
        'status': 'FULLY_PAID',
        'totalAmount': '100.00',
        'feeAmount': '0.00',
        'finalAmount': '100.00',
        'balance': '0.00',
        'isPartialPayment': false,
        'isFullyPaid': true,
        'totalPaidAmount': '100.00',
        'remainingBalance': '0.00',
        'exchangeRate': '40.0000',
        'createdAt': '2026-10-01T12:00:00.000Z',
        'orderItems': [
          {'id': 'oi-1', 'title': 'Producto Histórico', 'quantity': 1, 'price': '100.00'},
        ],
        'payments': [
          {
            'id': 'pay-1',
            'amount': '100.00',
            'exchangeRate': '41.0000',
            'currency': 'USD',
            'status': 'APPROVED',
            'paymentMethod': 'PAGO_MOVIL',
            'reference': '777888',
            'createdAt': '2026-10-01T12:05:00.000Z',
          },
        ],
      });

      final bytes = await OrderSalesControlPdfGenerator.generate(
        order,
        exchangeRate: const ExchangeRateConfig(enabled: true, rate: 55.0, symbol: 'Bs.'),
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    testWidgets(
      'OrderSalesControlDownloader opens via native MethodChannel and falls back to share when no viewer',
      (tester) async {
        OrderSalesControlDownloader.sharePdfHandlerForTest = null;
        OrderSalesControlDownloader.isAndroidOverrideForTest = null;
        addTearDown(() {
          OrderSalesControlDownloader.sharePdfHandlerForTest = null;
          OrderSalesControlDownloader.isAndroidOverrideForTest = null;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('com.tulojita/pdf_opener'),
            null,
          );
        });

        final tempFile = File(
          '${Directory.systemTemp.path}/test_sales_control_native_open.pdf',
        );
        tempFile.writeAsBytesSync([0x25, 0x50, 0x44, 0x46, 0x2D]);
        addTearDown(() {
          if (tempFile.existsSync()) tempFile.deleteSync();
        });

        final openedPaths = <String?>[];
        var shouldOpen = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.tulojita/pdf_opener'),
          (call) async {
            if (call.method == 'openPdf') {
              final args = call.arguments as Map<dynamic, dynamic>?;
              openedPaths.add(args?['path'] as String?);
              return shouldOpen;
            }
            return false;
          },
        );

        String? sharedFilename;
        OrderSalesControlDownloader.isAndroidOverrideForTest = true;
        OrderSalesControlDownloader.sharePdfHandlerForTest = (_, filename) async {
          sharedFilename = filename;
          return true;
        };

        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        final context = tester.element(find.byType(SizedBox));
        final sampleResult = SalesControlDownloadResult(
          file: tempFile,
          fileName: 'control_venta_TEST.pdf',
          displayLocation: 'Documentos',
        );

        await tester.runAsync(() async {
          await OrderSalesControlDownloader.openOrSharePdf(context, sampleResult);
        });
        expect(openedPaths, [tempFile.path]);
        expect(sharedFilename, isNull);

        shouldOpen = false;
        await tester.runAsync(() async {
          await OrderSalesControlDownloader.openOrSharePdf(context, sampleResult);
        });
        expect(sharedFilename, 'control_venta_TEST.pdf');
      },
    );
  });
}
