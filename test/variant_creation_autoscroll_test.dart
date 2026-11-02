import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/variant_management_section.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/step_pricing_and_variants.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  group('Variant Creation Autoscroll & Stability Tests', () {
    testWidgets(
        'StepPricingAndVariants has PageStorageKey configured on its SingleChildScrollView',
        (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StepPricingAndVariants(formKey: formKey),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollableFinder = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView &&
            w.key == const PageStorageKey('step_pricing_and_variants_scroll'),
      );
      expect(scrollableFinder, findsOneWidget);
    });

    testWidgets(
        'Adding a variant option auto-scrolls and displays the created option card',
        (tester) async {
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

      // 1. Enable variants
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // 2. Add an axis ("Talla")
      await tester.tap(find.text('Agregar Eje (Talla, Color...)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Talla').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear Eje'));
      await tester.pumpAndSettle();

      // 3. Add an option "XL"
      final addOptionBtn = find.text('Agregar opción a Talla');
      expect(addOptionBtn, findsOneWidget);
      await tester.tap(addOptionBtn);
      await tester.pumpAndSettle();

      // Type "XL" in the bottom sheet input
      final textFieldFinder = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'XL');
      await tester.pumpAndSettle();

      // Tap "Agregar Valor(es)"
      await tester.tap(find.text('Agregar Valor(es)'));
      await tester.pumpAndSettle();

      // Wait for delay in _scrollToTarget
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // 4. Verify bottom sheet is closed
      expect(find.byType(BottomSheet), findsNothing);

      // 5. Verify newly created option "XL" is rendered
      expect(find.text('XL'), findsWidgets);

      // 6. Verify unified option card contains price input for the option
      expect(find.text('Precio Opción (\$)'), findsOneWidget);
    });
  });
}
