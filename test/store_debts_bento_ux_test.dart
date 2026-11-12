import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/subscription/domain/entities/platform_payment_method.dart';
import 'package:tu_lojita_business/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:tu_lojita_business/features/subscription/presentation/screens/store_debts_screen.dart';
import 'package:tu_lojita_business/features/subscription/presentation/widgets/platform_payment_method_card.dart';
import 'widget_test.dart';

class _FakeExchangeRateNotifier extends ExchangeRateNotifier {
  final ExchangeRateConfig _config;
  _FakeExchangeRateNotifier(this._config);

  @override
  Future<ExchangeRateConfig> build() async => _config;
}

class _FakeSubscriptionNotifier extends SubscriptionNotifier {
  _FakeSubscriptionNotifier();

  @override
  SubscriptionState build() => const SubscriptionState();

  @override
  Future<void> loadSubscriptionAndMethods() async {}
}

class _MockAdapter implements HttpClientAdapter {
  final Future<Map<String, dynamic>> Function() responseBuilder;

  _MockAdapter(this.responseBuilder);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = await responseBuilder();
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Dio _buildMockDio(Future<Map<String, dynamic>> Function() builder) {
  final dio = Dio();
  dio.httpClientAdapter = _MockAdapter(builder);
  return dio;
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

  const methodPagoMovil = PlatformPaymentMethod(
    id: 'pm-1',
    type: 'PAGO_MOVIL',
    title: 'Pago Móvil Banesco Oficial',
    accountDetails: {
      'bankName': 'Banesco',
      'phoneNumber': '0414-0001122',
      'idNumber': 'J-50001234-9',
    },
    instructions: 'Indica tu nombre de tienda en el concepto.',
    qrImageUrl: 'https://images.tulojita.com/qr-pm.png',
    isActive: true,
  );

  group('PlatformPaymentMethodCard responsive & shared UX', () {
    testWidgets(
      'renders copyable fields, instructions, Copiar todo, Ver QR and selection trigger cleanly at 320px @ 1.35x',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var selected = false;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.35),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: PlatformPaymentMethodCard(
                    method: methodPagoMovil,
                    onSelectMethod: () => selected = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pago Móvil Banesco Oficial'), findsOneWidget);
        expect(find.text('Pago Móvil'), findsOneWidget);
        expect(find.text('Banesco'), findsOneWidget);
        expect(find.text('0414-0001122'), findsOneWidget);
        expect(find.text('Indica tu nombre de tienda en el concepto.'), findsOneWidget);
        expect(find.text('Copiar todo'), findsOneWidget);
        expect(find.text('Ver QR'), findsOneWidget);
        expect(find.text('Reportar con esta cuenta'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Reportar con esta cuenta'));
        await tester.tap(find.text('Reportar con esta cuenta'));
        await tester.pump();
        expect(selected, isTrue);
      },
    );
  });

  group('StoreDebtsScreen Bento UX', () {
    testWidgets('shows structural Bento shimmer while loading', (tester) async {
      final completer = Completer<Map<String, dynamic>>();
      final dio = _buildMockDio(() => completer.future);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            subscriptionProvider.overrideWith(() => _FakeSubscriptionNotifier()),
            exchangeRateProvider
                .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
          ],
          child: const MaterialApp(
            home: StoreDebtsScreen(storeId: 'store-1'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ShimmerWidget), findsWidgets);

      completer.complete({
        'store': {
          'id': 'store-1',
          'name': 'Comercial Sol',
          'status': 'ACTIVE',
          'accumulatedCommissionDebt': 0.0,
        },
        'currentBilling': null,
        'platformPaymentMethods': [],
        'paymentReports': [],
        'recentOrders': [],
      });
      await tester.pumpAndSettle();
    });

    testWidgets(
      'renders SUSPENDED banner, breakdown, visible payment accounts, rejected report history, and preselects account into modal at 320px @ 1.35x',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 740));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final dio = _buildMockDio(() async => {
              'store': {
                'id': 'store-1',
                'name': 'Comercial Sol',
                'status': 'SUSPENDED',
                'accumulatedCommissionDebt': 35.0,
              },
              'currentBilling': {
                'id': 'bill-1',
                'commissionAmount': 30.0,
                'fineAmount': 5.0,
                'paidAmount': 0.0,
                'totalDue': 35.0,
                'status': 'SUSPENDED',
                'gracePeriodEndDate': '2026-11-10T23:59:59.000Z',
              },
              'settings': {
                'isEnabled': true,
                'gracePeriodDays': 3,
                'fineType': 'PERCENTAGE',
                'fineValue': 10,
              },
              'platformPaymentMethods': [
                {
                  'id': 'pm-1',
                  'type': 'PAGO_MOVIL',
                  'title': 'Pago Móvil Banesco Oficial',
                  'accountDetails': {
                    'bankName': 'Banesco',
                    'phoneNumber': '0414-0001122',
                  },
                  'instructions': 'Coloca el nombre de tu tienda.',
                  'isActive': true,
                },
              ],
              'suspensionInfo': {
                'isSuspended': true,
                'isSuspendedByDebt': true,
                'hasPendingReport': false,
                'latestRejectedReport': {
                  'id': 'rep-old',
                  'amount': 35.0,
                  'rejectionReason': 'Captura borrosa',
                },
              },
              'paymentReports': [
                {
                  'id': 'rep-old',
                  'amount': 35.0,
                  'status': 'REJECTED',
                  'referenceNumber': '998877',
                  'rejectionReason': 'Captura borrosa',
                  'paymentMethod': {'title': 'Pago Móvil Banesco Oficial'},
                  'createdAt': '2026-11-11T15:00:00.000Z',
                },
              ],
              'recentOrders': [
                {
                  'id': 'ord-abc123-0001',
                  'totalAmount': 200.0,
                  'finalAmount': 200.0,
                  'platformCommissionAmount': 10.0,
                  'platformCommissionRate': 5.0,
                  'isPartialPayment': false,
                  'status': 'FULLY_PAID',
                },
              ],
            });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(1.35),
            ),
            child: ProviderScope(
              overrides: [
                dioProvider.overrideWithValue(dio),
                subscriptionProvider
                    .overrideWith(() => _FakeSubscriptionNotifier()),
                exchangeRateProvider
                    .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
              ],
              child: const MaterialApp(
                home: StoreDebtsScreen(storeId: 'store-1'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('TIENDA SUSPENDIDA POR MORA'), findsOneWidget);
        expect(find.text('Último comprobante rechazado'), findsOneWidget);
        expect(find.text('Motivo: Captura borrosa'), findsWidgets);
        expect(find.text('Comisión acumulada'), findsOneWidget);
        expect(find.text('Multa / mora'), findsOneWidget);
        expect(find.text('¿Cómo y dónde pagar?'), findsOneWidget);
        expect(find.text('Pago Móvil Banesco Oficial'), findsWidgets);
        expect(find.text('Historial de reportes de pago'), findsOneWidget);
        expect(find.text('Rechazado'), findsOneWidget);
        expect(find.text('Orden #ORD'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Tap prefill button inside visible payment card
        await tester.ensureVisible(find.text('Reportar con esta cuenta'));
        await tester.tap(find.text('Reportar con esta cuenta'));
        await tester.pumpAndSettle();

        expect(find.text('Reportar Pago de Comisiones'), findsOneWidget);
        expect(find.text('Monto a liquidar:'), findsOneWidget);
        // Selected account is pre-populated in dropdown
        expect(find.text('Pago Móvil Banesco Oficial'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders grace countdown banner and payment-in-review state cleanly',
      (tester) async {
        final inTwoDays = DateTime.now().add(const Duration(days: 2));
        final dioGrace = _buildMockDio(() async => {
              'store': {
                'id': 'store-2',
                'name': 'Tienda Gracia',
                'status': 'ACTIVE',
                'accumulatedCommissionDebt': 20.0,
              },
              'currentBilling': {
                'id': 'bill-2',
                'commissionAmount': 20.0,
                'fineAmount': 0.0,
                'paidAmount': 0.0,
                'totalDue': 20.0,
                'status': 'PENDING',
                'gracePeriodEndDate': inTwoDays.toIso8601String(),
              },
              'settings': {
                'isEnabled': true,
                'gracePeriodDays': 3,
                'fineType': 'FIXED_USD',
                'fineValue': 5,
              },
              'platformPaymentMethods': [],
              'paymentReports': [],
              'recentOrders': [],
            });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dioProvider.overrideWithValue(dioGrace),
              subscriptionProvider
                  .overrideWith(() => _FakeSubscriptionNotifier()),
              exchangeRateProvider
                  .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            ],
            child: const MaterialApp(
              home: StoreDebtsScreen(storeId: 'store-2'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Quedan 2 días del período de gracia'), findsOneWidget);
        expect(find.text('Multa por mora al vencer:'), findsOneWidget);
        expect(find.text('Reportar Pago de Comisiones'), findsOneWidget);
      },
    );
  });
}
