import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
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
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\nAPI_KEY_IMAGES=test-images-key\n',
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

    testWidgets(
      'displays receipt thumbnail with remove button, renders history receipt thumbnail, and deletes orphan image if commission report POST fails',
      (tester) async {
        // Minimal valid 1x1 PNG bytes so Image.file decodes cleanly in test
        const validPng = <int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
          0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
          0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
          0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ];
        final tempFile = File(
          '${Directory.systemTemp.path}/receipt_test_${DateTime.now().microsecondsSinceEpoch}.png',
        )..writeAsBytesSync(validPng);
        addTearDown(() {
          if (tempFile.existsSync()) tempFile.deleteSync();
        });

        final fakeImageSource = _RecordingImageRemoteDataSource(
          uploadReturnUrl: '/img/orphan-comm-uuid',
        );

        final dioFailPost = Dio();
        dioFailPost.httpClientAdapter = _RoutingAdapter((options) async {
          if (options.method == 'GET' && options.path.contains('/debt-hub')) {
            return _MockHttpResp(200, {
              'store': {
                'id': 'store-1',
                'name': 'Comercial Sol',
                'status': 'SUSPENDED',
                'accumulatedCommissionDebt': 10.0,
              },
              'currentBilling': {
                'id': 'bill-1',
                'commissionAmount': 10.0,
                'fineAmount': 0.0,
                'paidAmount': 0.0,
                'totalDue': 10.0,
                'status': 'SUSPENDED',
              },
              'platformPaymentMethods': [
                {
                  'id': 'pm-1',
                  'type': 'PAGO_MOVIL',
                  'title': 'Pago Móvil Banesco Oficial',
                  'accountDetails': {'phoneNumber': '0414-0001122'},
                  'isActive': true,
                },
              ],
              'paymentReports': [
                {
                  'id': 'rep-hist-1',
                  'amount': 10.0,
                  'status': 'REJECTED',
                  'referenceNumber': '445566',
                  'rejectionReason': 'Ilegible',
                  'receiptImageUrl': '/img/hist-receipt-1',
                  'paymentMethod': {'title': 'Pago Móvil Banesco Oficial'},
                },
              ],
              'recentOrders': [],
            });
          }
          if (options.method == 'POST' &&
              options.path.contains('/payment-reports')) {
            return _MockHttpResp(500, {'message': 'Backend error'});
          }
          return _MockHttpResp(200, {});
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dioProvider.overrideWithValue(dioFailPost),
              imageRemoteDataSourceProvider.overrideWithValue(fakeImageSource),
              subscriptionProvider
                  .overrideWith(() => _FakeSubscriptionNotifier()),
              exchangeRateProvider
                  .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            ],
            child: MaterialApp(
              home: StoreDebtsScreen(
                storeId: 'store-1',
                receiptPickerOverride: (_) async => tempFile,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // History card renders clickable network receipt thumbnail
        expect(find.byType(Image), findsWidgets);

        // Open modal via visible payment method card
        await tester.ensureVisible(find.text('Reportar con esta cuenta'));
        await tester.tap(find.text('Reportar con esta cuenta'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, '123456');

        // Pick from Galería -> displays Image.file thumbnail + zoom label (NOT raw filename text)
        await tester.tap(find.text('Galería'));
        await tester.pumpAndSettle();

        expect(find.text('Toca para ampliar'), findsOneWidget);
        expect(find.byKey(const Key('remove_receipt_btn')), findsOneWidget);
        expect(find.textContaining('Comprobante seleccionado:'), findsNothing);

        // Clear via remove button -> returns Cámara / Galería pickers
        await tester.tap(find.byKey(const Key('remove_receipt_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Galería'), findsOneWidget);
        expect(find.text('Toca para ampliar'), findsNothing);

        // Pick again & submit -> upload succeeds, POST fails -> orphan image deleted automatically
        await tester.tap(find.text('Galería'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Confirmar y Enviar Comprobante'));
        await tester.tap(find.text('Confirmar y Enviar Comprobante'));
        await tester.pumpAndSettle();

        expect(fakeImageSource.uploadedCount, 1);
        expect(fakeImageSource.deletedUrls, ['/img/orphan-comm-uuid']);
        expect(tester.takeException(), isNull);
      },
    );

    test(
        'ImageRemoteDataSourceImpl.deleteImage strips query/full URL and SubscriptionNotifier deletes orphan receipt when POST fails',
        () async {
      final deletedPaths = <String>[];
      final dio = Dio();
      dio.httpClientAdapter = _RoutingAdapter((options) async {
        if (options.method == 'DELETE') {
          deletedPaths.add(options.uri.toString());
          return _MockHttpResp(200, {'status': 'success'});
        }
        return _MockHttpResp(200, {});
      });

      final ds = ImageRemoteDataSourceImpl(dio);
      await ds.deleteImage(
        'https://images.tulojita.com/img/uuid-abc-123.webp?w=200',
      );
      expect(
        deletedPaths,
        ['https://images.tulojita.com/img/uuid-abc-123'],
      );

      // SubscriptionNotifier rollback check
      final fakeSubImgSource = _RecordingImageRemoteDataSource(
        uploadReturnUrl: '/img/sub-orphan-77',
      );
      final subDio = Dio();
      subDio.httpClientAdapter = _RoutingAdapter((options) async {
        if (options.method == 'POST' &&
            options.path == '/subscriptions/report-payment') {
          return _MockHttpResp(500, {'message': 'Sub error'});
        }
        return _MockHttpResp(200, {});
      });

      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(subDio),
          imageRemoteDataSourceProvider.overrideWithValue(fakeSubImgSource),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(subscriptionProvider.notifier)
          .reportSubscriptionPayment(
            amount: 20.0,
            paymentMethodId: 'pm-1',
            referenceNumber: '9911',
            receiptFile: File('dummy.png'),
          );

      expect(result, isFalse);
      expect(fakeSubImgSource.deletedUrls, ['/img/sub-orphan-77']);
    });

    testWidgets(
      'paginates commission orders 20-by-20, renders order thumbnails and navigates to order details on tap',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 780));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final recordedOrderOffsets = <int>[];
        String? pushedRoute;

        final pagedDio = Dio();
        pagedDio.httpClientAdapter = _RoutingAdapter((options) async {
          if (options.path.endsWith('/debt-hub')) {
            return _MockHttpResp(200, {
              'store': {
                'id': 'store-1',
                'name': 'Comercial Sol',
                'status': 'ACTIVE',
                'accumulatedCommissionDebt': 12.0,
              },
              'currentBilling': null,
              'platformPaymentMethods': const [],
              'paymentReports': const [],
              'recentOrders': const [],
            });
          }
          if (options.path.endsWith('/orders')) {
            final offset =
                int.tryParse(options.queryParameters['offset']?.toString() ?? '0') ??
                    0;
            recordedOrderOffsets.add(offset);
            if (offset == 0) {
              return _MockHttpResp(200, {
                'items': List.generate(
                  20,
                  (i) => {
                    'id': 'ord-${i + 1}-uuid',
                    'totalAmount': 40.0,
                    'finalAmount': 40.0,
                    'platformCommissionRate': 5.0,
                    'platformCommissionAmount': 2.0,
                    'isPartialPayment': false,
                    'status': 'FULLY_PAID',
                    'createdAt': '2026-11-12T10:00:00.000Z',
                    'itemImageUrl': i == 0 ? '/img/order-thumb-1.webp' : null,
                    'firstItemTitle': i == 0 ? 'Taladro Brushless' : 'Producto ${i + 1}',
                    'itemsCount': i == 0 ? 3 : 1,
                  },
                ),
                'total': 22,
                'limit': 20,
                'offset': 0,
                'hasMore': true,
              });
            }
            return _MockHttpResp(200, {
              'items': [
                {
                  'id': 'ord-21-uuid',
                  'totalAmount': 60.0,
                  'finalAmount': 60.0,
                  'platformCommissionRate': 5.0,
                  'platformCommissionAmount': 3.0,
                  'isPartialPayment': true,
                  'status': 'PARTIALLY_PAID',
                  'createdAt': '2026-11-11T10:00:00.000Z',
                  'itemImageUrl': null,
                  'firstItemTitle': 'Lijadora Orbital',
                  'itemsCount': 1,
                },
                {
                  'id': 'ord-22-uuid',
                  'totalAmount': 20.0,
                  'finalAmount': 20.0,
                  'platformCommissionRate': 5.0,
                  'platformCommissionAmount': 1.0,
                  'isPartialPayment': false,
                  'status': 'FULLY_PAID',
                  'createdAt': '2026-11-10T10:00:00.000Z',
                  'itemImageUrl': null,
                  'firstItemTitle': 'Cinta Métrica',
                  'itemsCount': 1,
                },
              ],
              'total': 22,
              'limit': 20,
              'offset': 20,
              'hasMore': false,
            });
          }
          return _MockHttpResp(200, {});
        });

        final router = GoRouter(
          initialLocation: '/debts',
          routes: [
            GoRoute(
              path: '/debts',
              builder: (_, _) => const StoreDebtsScreen(storeId: 'store-1'),
            ),
            GoRoute(
              path: '/dashboard/orders/:orderId',
              builder: (_, state) {
                pushedRoute = state.uri.toString();
                return Scaffold(
                  body: Text('Detalle ${state.pathParameters['orderId']}'),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dioProvider.overrideWithValue(pagedDio),
              subscriptionProvider.overrideWith(() => _FakeSubscriptionNotifier()),
              exchangeRateProvider
                  .overrideWith(() => _FakeExchangeRateNotifier(enabledRate)),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(recordedOrderOffsets, [0]);
        expect(
          find.text('Mostrando 20 de 22 órdenes pagadas o abonadas.'),
          findsOneWidget,
        );
        expect(find.text('Taladro Brushless'), findsOneWidget);
        expect(find.text('+2'), findsOneWidget);

        final thumbImages = tester.widgetList<Image>(find.byType(Image));
        expect(
          thumbImages.any(
            (img) =>
                img.image is NetworkImage &&
                (img.image as NetworkImage).url ==
                    'https://images.tulojita.com/img/order-thumb-1.webp',
          ),
          isTrue,
        );

        // Load next page via explicit button
        final loadMoreFinder = find.text('Cargar más órdenes (2)');
        await tester.ensureVisible(loadMoreFinder);
        await tester.tap(loadMoreFinder);
        await tester.pumpAndSettle();

        expect(recordedOrderOffsets, [0, 20]);
        expect(
          find.text('Mostrando 22 de 22 órdenes pagadas o abonadas.'),
          findsOneWidget,
        );
        expect(find.text('Lijadora Orbital'), findsOneWidget);
        expect(find.text('Cargar más órdenes (2)'), findsNothing);

        // Tap first order card -> navigates to /dashboard/orders/ord-1-uuid
        final firstOrderFinder = find.text('Taladro Brushless');
        await tester.ensureVisible(firstOrderFinder);
        await tester.tap(firstOrderFinder);
        await tester.pumpAndSettle();

        expect(pushedRoute, '/dashboard/orders/ord-1-uuid');
        expect(find.text('Detalle ord-1-uuid'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders segmented filter chips with counts, filters orders reactively, renders 56x56 thumbnails with multi-item breakdown and expands inline without ambiguous Pagada badge at 320px @ 1.35x',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final recordedFilters = <String>[];
        final testDio = Dio();
        testDio.httpClientAdapter = _RoutingAdapter((options) async {
          final uri = options.uri.toString();
          if (uri.contains('/debt-hub')) {
            return const _MockHttpResp(200, {
              'store': {
                'id': 'store-1',
                'name': 'Pastelería Dulce',
                'status': 'ACTIVE',
                'accumulatedCommissionDebt': 15.0,
              },
              'currentBilling': null,
              'platformPaymentMethods': [],
              'paymentReports': [],
              'recentOrders': [],
            });
          }
          if (uri.contains('/orders')) {
            final filter =
                options.queryParameters['filter']?.toString() ?? 'all';
            recordedFilters.add(filter);

            if (filter == 'pending') {
              return const _MockHttpResp(200, {
                'items': [
                  {
                    'id': 'ord-p1-uuid',
                    'totalAmount': 50.0,
                    'finalAmount': 50.0,
                    'platformCommissionRate': 5.0,
                    'platformCommissionAmount': 2.5,
                    'isPartialPayment': false,
                    'status': 'FULLY_PAID',
                    'commissionStatus': 'PENDING',
                    'itemImageUrl':
                        'https://images.tulojita.com/img/torta.webp',
                    'firstItemTitle': 'Torta Selva Negra',
                    'itemsCount': 3,
                    'items': [
                      {
                        'id': 'it-1',
                        'title': 'Torta Selva Negra',
                        'quantity': 2,
                        'price': 20.0,
                        'variantLabel': 'Grande / Chocolate',
                        'imageUrl':
                            'https://images.tulojita.com/img/torta.webp',
                      },
                      {
                        'id': 'it-2',
                        'title': 'Cupcake Vainilla',
                        'quantity': 1,
                        'price': 10.0,
                        'variantLabel': '',
                        'imageUrl': '',
                      },
                    ],
                  },
                ],
                'total': 1,
                'limit': 20,
                'offset': 0,
                'hasMore': false,
                'summaryCounts': {
                  'all': 3,
                  'pending': 1,
                  'collected': 1,
                  'exempt': 1,
                },
              });
            } else if (filter == 'collected') {
              return const _MockHttpResp(200, {
                'items': [
                  {
                    'id': 'ord-c1-uuid',
                    'totalAmount': 100.0,
                    'finalAmount': 100.0,
                    'platformCommissionRate': 5.0,
                    'platformCommissionAmount': 5.0,
                    'isPartialPayment': false,
                    'status': 'FULLY_PAID',
                    'commissionStatus': 'COLLECTED',
                    'settlementBillingId': 'bill-cut-999',
                    'itemImageUrl': 'https://images.tulojita.com/img/pie.webp',
                    'firstItemTitle': 'Pie de Limón',
                    'itemsCount': 1,
                    'items': [
                      {
                        'id': 'it-3',
                        'title': 'Pie de Limón',
                        'quantity': 1,
                        'price': 100.0,
                        'variantLabel': 'Familiar',
                        'imageUrl':
                            'https://images.tulojita.com/img/pie.webp',
                      },
                    ],
                  },
                ],
                'total': 1,
                'limit': 20,
                'offset': 0,
                'hasMore': false,
                'summaryCounts': {
                  'all': 3,
                  'pending': 1,
                  'collected': 1,
                  'exempt': 1,
                },
              });
            }

            return const _MockHttpResp(200, {
              'items': [
                {
                  'id': 'ord-p1-uuid',
                  'totalAmount': 50.0,
                  'finalAmount': 50.0,
                  'platformCommissionRate': 5.0,
                  'platformCommissionAmount': 2.5,
                  'isPartialPayment': false,
                  'status': 'FULLY_PAID',
                  'commissionStatus': 'PENDING',
                  'itemImageUrl':
                      'https://images.tulojita.com/img/torta.webp',
                  'firstItemTitle': 'Torta Selva Negra',
                  'itemsCount': 3,
                  'items': [
                    {
                      'id': 'it-1',
                      'title': 'Torta Selva Negra',
                      'quantity': 2,
                      'price': 20.0,
                      'variantLabel': 'Grande / Chocolate',
                      'imageUrl':
                          'https://images.tulojita.com/img/torta.webp',
                    },
                    {
                      'id': 'it-2',
                      'title': 'Cupcake Vainilla',
                      'quantity': 1,
                      'price': 10.0,
                      'variantLabel': '',
                      'imageUrl': '',
                    },
                  ],
                },
                {
                  'id': 'ord-c1-uuid',
                  'totalAmount': 100.0,
                  'finalAmount': 100.0,
                  'platformCommissionRate': 5.0,
                  'platformCommissionAmount': 5.0,
                  'isPartialPayment': false,
                  'status': 'FULLY_PAID',
                  'commissionStatus': 'COLLECTED',
                  'settlementBillingId': 'bill-cut-999',
                  'itemImageUrl': 'https://images.tulojita.com/img/pie.webp',
                  'firstItemTitle': 'Pie de Limón',
                  'itemsCount': 1,
                  'items': [
                    {
                      'id': 'it-3',
                      'title': 'Pie de Limón',
                      'quantity': 1,
                      'price': 100.0,
                      'variantLabel': 'Familiar',
                      'imageUrl':
                          'https://images.tulojita.com/img/pie.webp',
                    },
                  ],
                },
                {
                  'id': 'ord-e1-uuid',
                  'totalAmount': 30.0,
                  'finalAmount': 30.0,
                  'platformCommissionRate': 0.0,
                  'platformCommissionAmount': 0.0,
                  'isPartialPayment': false,
                  'status': 'FULLY_PAID',
                  'commissionStatus': 'EXEMPT',
                  'itemImageUrl': '',
                  'firstItemTitle': 'Café Exento',
                  'itemsCount': 1,
                  'items': [
                    {
                      'id': 'it-4',
                      'title': 'Café Exento',
                      'quantity': 1,
                      'price': 30.0,
                      'variantLabel': '',
                      'imageUrl': '',
                    },
                  ],
                },
              ],
              'total': 3,
              'limit': 20,
              'offset': 0,
              'hasMore': false,
              'summaryCounts': {
                'all': 3,
                'pending': 1,
                'collected': 1,
                'exempt': 1,
              },
            });
          }
          return const _MockHttpResp(200, {});
        });

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.35),
            ),
            child: ProviderScope(
              overrides: [
                dioProvider.overrideWithValue(testDio),
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

        expect(recordedFilters, ['all']);

        // Check filter tabs and their counts
        expect(
          find.byKey(const Key('commission_filter_all')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('commission_filter_pending')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('commission_filter_collected')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('commission_filter_exempt')),
          findsOneWidget,
        );

        expect(find.text('Todas'), findsOneWidget);
        expect(find.text('Por pagar'), findsWidgets);
        expect(find.text('Liquidadas'), findsOneWidget);
        expect(find.text('Exentas'), findsOneWidget);

        // Ambiguous "Pagada" badge is NOT rendered anywhere
        expect(find.text('Pagada'), findsNothing);

        // Check commission badges
        expect(find.text('Comisión saldada ✓'), findsOneWidget);
        expect(find.text('Liquidada en corte #BILL'), findsOneWidget);
        expect(find.text('Exenta 0%'), findsOneWidget);

        // Check primary product formatted with quantity and variant
        expect(
          find.text('2 x Torta Selva Negra · Grande / Chocolate'),
          findsOneWidget,
        );
        expect(find.text('+2'), findsOneWidget);
        expect(find.text('Ver 1 producto más'), findsOneWidget);

        // Expand inline basket
        await tester.ensureVisible(find.text('Ver 1 producto más'));
        await tester.tap(find.text('Ver 1 producto más'));
        await tester.pumpAndSettle();

        expect(find.text('Ocultar productos'), findsOneWidget);
        expect(find.text('1x Cupcake Vainilla'), findsOneWidget);

        // Tap filter chip "Por pagar"
        await tester.ensureVisible(
          find.byKey(const Key('commission_filter_pending')),
        );
        await tester.tap(find.byKey(const Key('commission_filter_pending')));
        await tester.pumpAndSettle();

        expect(recordedFilters, ['all', 'pending']);
        expect(
          find.text('2 x Torta Selva Negra · Grande / Chocolate'),
          findsOneWidget,
        );
        expect(find.text('1 x Pie de Limón · Familiar'), findsNothing);
        expect(find.text('1 x Café Exento'), findsNothing);

        // Tap filter chip "Liquidadas"
        await tester.ensureVisible(
          find.byKey(const Key('commission_filter_collected')),
        );
        await tester.tap(
          find.byKey(const Key('commission_filter_collected')),
        );
        await tester.pumpAndSettle();

        expect(recordedFilters, ['all', 'pending', 'collected']);
        expect(find.text('1 x Pie de Limón · Familiar'), findsOneWidget);
        expect(find.text('Torta Selva Negra'), findsNothing);
        expect(find.text('Liquidada en corte #BILL'), findsOneWidget);

        // Verify zero RenderFlex overflows at 320px
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _MockHttpResp {
  final int statusCode;
  final Map<String, dynamic> body;
  const _MockHttpResp(this.statusCode, this.body);
}

class _RoutingAdapter implements HttpClientAdapter {
  final Future<_MockHttpResp> Function(RequestOptions options) handler;

  _RoutingAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final resp = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(resp.body),
      resp.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RecordingImageRemoteDataSource implements ImageRemoteDataSource {
  final String uploadReturnUrl;
  int uploadedCount = 0;
  final List<String> deletedUrls = [];

  _RecordingImageRemoteDataSource({required this.uploadReturnUrl});

  @override
  Future<String> uploadImage(File file) async {
    uploadedCount++;
    return uploadReturnUrl;
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    deletedUrls.add(imageUrl);
  }
}
