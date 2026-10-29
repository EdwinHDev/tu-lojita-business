import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/orders/domain/entities/order_dispute.dart';
import 'package:tu_lojita_business/features/orders/domain/enums/dispute_enums.dart';
import 'package:tu_lojita_business/features/orders/presentation/widgets/dispute_alert_banner.dart';

OrderDispute createTestDispute({
  String id = 'dispute-1',
  String orderId = 'order-1',
  DisputeStatus status = DisputeStatus.adminReview,
  DisputeType type = DisputeType.refundRequest,
  String reason = 'El pago fue debitado de mi cuenta bancaria',
}) {
  return OrderDispute(
    id: id,
    orderId: orderId,
    userId: 'user-1',
    type: type,
    status: status,
    reason: reason,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  testWidgets('DisputeAlertBanner in ADMIN_REVIEW shows administrative mediation and hides actions', (tester) async {
    final dispute = createTestDispute(status: DisputeStatus.adminReview);
    bool respondCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisputeAlertBanner(
            dispute: dispute,
            onRespond: () => respondCalled = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Debe mostrar título de mediación con soporte
    expect(find.text('Pedido en mediación con Soporte'), findsOneWidget);

    // Debe mostrar mensaje de contacto de soporte
    expect(
      find.text(
        'Este caso fue escalado a una disputa y está en proceso de revisión por el equipo de soporte. Es posible que el soporte se ponga en contacto contigo para resolver el caso.',
      ),
      findsOneWidget,
    );

    // Debe mostrar chip En Mediación
    expect(find.text('En Mediación'), findsOneWidget);

    // NO debe mostrar el botón Responder al Reclamo
    expect(find.text('Responder al Reclamo'), findsNothing);

    // Debe mostrar botón Hablar con Soporte
    expect(find.text('Hablar con Soporte'), findsOneWidget);

    // NO debe mostrar Marcar resuelto
    expect(find.text('Marcar resuelto'), findsNothing);
    expect(respondCalled, isFalse);
  });

  testWidgets('DisputeAlertBanner in OPEN shows response required and action button', (tester) async {
    final dispute = createTestDispute(status: DisputeStatus.open);
    bool respondCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisputeAlertBanner(
            dispute: dispute,
            onRespond: () => respondCalled = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Debe mostrar reclamo pendiente de respuesta
    expect(find.text('¡RECLAMO PENDIENTE DE RESPUESTA!'), findsOneWidget);

    // Debe mostrar botón Responder al Reclamo
    expect(find.text('Responder al Reclamo'), findsOneWidget);

    // Al presionar el botón se debe invocar onRespond
    await tester.tap(find.text('Responder al Reclamo'));
    await tester.pumpAndSettle();
    expect(respondCalled, isTrue);

    // NO debe mostrar texto de mediación administrativa
    expect(find.text('Pedido en mediación administrativa'), findsNothing);
  });
}
