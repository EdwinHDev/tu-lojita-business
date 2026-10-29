import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/variant_management_section.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  testWidgets(
      'VariantManagementSection opens keyboard-safe bottom sheet without RenderFlex overflow',
      (tester) async {
    final List<FlutterErrorDetails> errors = [];
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      FlutterError.dumpErrorToConsole(details);
    };

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: VariantManagementSection(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify section title and toggle
    expect(find.text('Variantes del Artículo'), findsOneWidget);
    expect(find.text('Habilitar Variantes'), findsOneWidget);

    // 2. Toggle variants switch to ON
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // 3. Find and tap "Agregar Eje (Talla, Color...)"
    final addAxisBtn = find.text('Agregar Eje (Talla, Color...)');
    expect(addAxisBtn, findsOneWidget);

    // Simulate active software keyboard taking up 320 logical pixels from bottom
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);

    await tester.tap(addAxisBtn);
    await tester.pumpAndSettle();

    // 4. Verify ModalBottomSheet is displayed instead of AlertDialog
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // 5. Verify Bottom Sheet header and content
    expect(find.text('Nuevo Eje de Variación'), findsOneWidget);
    expect(find.text('Escribe el nombre del atributo o selecciona una sugerencia'), findsOneWidget);

    // 6. Verify suggestions are present
    expect(find.text('Talla'), findsWidgets);
    expect(find.text('Color'), findsWidgets);
    expect(find.text('Material'), findsWidgets);

    // 7. Verify thumb-zone action button exists
    expect(find.text('Crear Eje'), findsOneWidget);

    // 8. Tap "Talla" suggestion
    await tester.tap(find.text('Talla').first);
    await tester.pumpAndSettle();

    // 9. Tap "Crear Eje"
    await tester.tap(find.text('Crear Eje'));
    await tester.pumpAndSettle();

    // 10. Sheet dismissed and axis created
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Talla'), findsWidgets);

    // Verify ZERO RenderFlex overflow errors occurred
    final overflowErrors = errors.where((e) => e.toString().contains('overflowed')).toList();
    expect(overflowErrors, isEmpty, reason: 'Expected zero viewport or RenderFlex overflows with active keyboard');
  });
}
