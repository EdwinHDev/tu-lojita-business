import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
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

  group('Variant Stock Stepper & Label Tests', () {
    testWidgets('Stock stepper displays label, increments, decrements, and clamps to 0',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  return const SingleChildScrollView(
                    child: VariantManagementSection(),
                  );
                },
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

      // 3. Add an option "M"
      await tester.tap(find.text('Agregar opción a Talla'));
      await tester.pumpAndSettle();

      final bottomSheetField = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(bottomSheetField, 'M');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar Valor(es)'));
      await tester.pumpAndSettle();

      // 4. Verify label "Stock disponible" exists on the option card
      expect(find.text('Stock disponible'), findsOneWidget);

      // 5. Verify initial stock is 0
      final stockInputFinder = find.byKey(const ValueKey('stock_field_0'));
      expect(stockInputFinder, findsOneWidget);
      expect(find.descendant(of: stockInputFinder, matching: find.text('0')), findsOneWidget);

      // Verify state has stock 0
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 0.0);

      // 6. Tap Plus button (+)
      final plusBtnFinder = find.byKey(const ValueKey('stock_increment_btn_0'));
      expect(plusBtnFinder, findsOneWidget);
      await tester.tap(plusBtnFinder);
      await tester.pumpAndSettle();

      // Verify UI and State updated to 1
      expect(find.descendant(of: stockInputFinder, matching: find.text('1')), findsOneWidget);
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 1.0);

      // Tap Plus button (+) again -> 2
      await tester.tap(plusBtnFinder);
      await tester.pumpAndSettle();
      expect(find.descendant(of: stockInputFinder, matching: find.text('2')), findsOneWidget);
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 2.0);

      // 7. Tap Minus button (-) -> 1
      final minusBtnFinder = find.byKey(const ValueKey('stock_decrement_btn_0'));
      expect(minusBtnFinder, findsOneWidget);
      await tester.tap(minusBtnFinder);
      await tester.pumpAndSettle();
      expect(find.descendant(of: stockInputFinder, matching: find.text('1')), findsOneWidget);
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 1.0);

      // Tap Minus button (-) again -> 0
      await tester.tap(minusBtnFinder);
      await tester.pumpAndSettle();
      expect(find.descendant(of: stockInputFinder, matching: find.text('0')), findsOneWidget);
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 0.0);

      // 8. Tap Minus button (-) when already 0 -> remains 0 (minimum 0 check)
      await tester.tap(minusBtnFinder);
      await tester.pumpAndSettle();
      expect(find.descendant(of: stockInputFinder, matching: find.text('0')), findsOneWidget);
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 0.0);

      // 9. Manual direct entry: enter "50"
      await tester.enterText(stockInputFinder, '50');
      await tester.pumpAndSettle();
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 50.0);

      // Tap Plus (+) after manual entry -> 51
      await tester.tap(plusBtnFinder);
      await tester.pumpAndSettle();
      expect(find.descendant(of: stockInputFinder, matching: find.text('51')), findsOneWidget);
      expect(capturedRef.read(itemFormProvider).variants.first.stockQuantity, 51.0);
    });
  });
}

