import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/widgets/premium_snackbar.dart';

void main() {
  testWidgets('NotificationService displays PremiumSnackBarContent on OverlayEntry',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  NotificationService.showSuccess(
                    context,
                    '¡Vitrina actualizada exitosamente!',
                  );
                },
                child: const Text('Mostrar Notificación'),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: No notification
    expect(find.byType(PremiumSnackBarContent), findsNothing);

    // Tap button to trigger notification
    await tester.tap(find.text('Mostrar Notificación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify PremiumSnackBarContent is mounted
    expect(find.byType(PremiumSnackBarContent), findsOneWidget);
    expect(find.text('¡Vitrina actualizada exitosamente!'), findsOneWidget);
    expect(find.text('¡Éxito!'), findsOneWidget);

    // Verify that NO standard Flutter SnackBar is used
    expect(find.byType(SnackBar), findsNothing);
  });
}

