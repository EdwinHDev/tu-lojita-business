import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_card.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_detail_helpers.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/order_detail/order_payments_card.dart';

class _FakeBusinessExchangeRateNotifier extends ExchangeRateNotifier {
  @override
  Future<ExchangeRateConfig> build() async {
    return const ExchangeRateConfig(enabled: false, rate: 50.0);
  }
}

void main() {
  test('OrderDetailHelpers formats DEFERRED_ZERO_INITIAL clearly', () {
    expect(
      OrderDetailHelpers.formatPaymentMethod('DEFERRED_ZERO_INITIAL'),
      'Inicial \$0.00 Diferida',
    );
  });

  testWidgets(
    'OrderCard and OrderPaymentsCard render PARTIALLY_PAID & AWAITING_STOCK orders with empty payments safely',
    (tester) async {
      final deferredOrder = Order.fromJson({
        'id': 'ord-zero-1',
        'status': 'PARTIALLY_PAID',
        'totalAmount': 60,
        'feeAmount': 0,
        'finalAmount': 60,
        'balance': 60,
        'isPartialPayment': true,
        'totalPaidAmount': 0,
        'remainingBalance': 60,
        'createdAt': '2026-11-12T12:00:00.000Z',
        'orderItems': [
          {
            'id': 'oi-1',
            'quantity': 1,
            'priceAtPurchase': 60,
            'item': {'id': 'it-1', 'title': 'Cloro 20L', 'images': []},
          }
        ],
        'payments': [],
        'installments': [],
        'user': {'firstName': 'Ana', 'lastName': 'Perez'},
      });

      final freePreOrder = Order.fromJson({
        'id': 'ord-free-pre-1',
        'status': 'PENDING',
        'preOrderStatus': 'AWAITING_STOCK',
        'totalAmount': 80,
        'feeAmount': 0,
        'finalAmount': 80,
        'balance': 80,
        'isPartialPayment': false,
        'totalPaidAmount': 0,
        'remainingBalance': 80,
        'createdAt': '2026-11-12T12:00:00.000Z',
        'orderItems': [
          {
            'id': 'oi-2',
            'quantity': 1,
            'priceAtPurchase': 80,
            'item': {'id': 'it-2', 'title': 'Preventa Especial', 'images': []},
          }
        ],
        'payments': [],
        'installments': [],
        'user': {'firstName': 'Luis', 'lastName': 'Gomez'},
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exchangeRateProvider
                .overrideWith(() => _FakeBusinessExchangeRateNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  OrderCard(order: deferredOrder, onTap: () {}),
                  OrderCard(order: freePreOrder, onTap: () {}),
                  OrderPaymentsCard(order: deferredOrder),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Inicial \$0.00'), findsOneWidget);
      expect(find.text('Reserva \$0.00'), findsOneWidget);
    },
  );
}
