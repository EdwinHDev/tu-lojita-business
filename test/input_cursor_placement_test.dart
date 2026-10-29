import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/utils/safe_text_controller.dart';
import 'package:tu_lojita_business/core/utils/rif_input_formatter.dart';

void main() {
  group('SafeTextEditingController Tests (Merchant App)', () {
    test('createSafeController initializes with collapsed offset at text length', () {
      final ctrl = createSafeController(text: '500');
      expect(ctrl.text, '500');
      expect(ctrl.selection.isValid, isTrue);
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 3);
      expect(ctrl.selection.extentOffset, 3);
    });

    test('createSafeController with null or empty text has valid offset 0', () {
      final ctrl = createSafeController();
      expect(ctrl.text, '');
      expect(ctrl.selection.isValid, isTrue);
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 0);
    });

    test('safeSetText preserves valid collapsed selection at length', () {
      final ctrl = TextEditingController();
      ctrl.safeSetText('1250.50');
      expect(ctrl.text, '1250.50');
      expect(ctrl.selection.isValid, isTrue);
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 7);
    });

    test('collapseToEnd collapses range selection to the end', () {
      final ctrl = TextEditingController(text: 'Hello');
      ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      expect(ctrl.selection.isCollapsed, isFalse);

      ctrl.collapseToEnd();
      expect(ctrl.selection.isCollapsed, isTrue);
      expect(ctrl.selection.baseOffset, 5);
    });
  });

  group('RifTextInputFormatter Cursor Preservation', () {
    test('Preserves cursor when formatting text', () {
      final formatter = RifTextInputFormatter();
      final oldValue = const TextEditingValue(
        text: 'J-',
        selection: TextSelection.collapsed(offset: 2),
      );
      final newValue = const TextEditingValue(
        text: 'J-12345678',
        selection: TextSelection.collapsed(offset: 10),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, 'J-12345678');
      expect(result.selection.isValid, isTrue);
      expect(result.selection.isCollapsed, isTrue);
      expect(result.selection.baseOffset, 10);
    });
  });

  group('Input Tap & Precision Placement Tests', () {
    testWidgets('Tapping TextField with safe controller does not select all text', (tester) async {
      final controller = createSafeController(text: '500.00');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: TextField(
                  key: const ValueKey('credit_limit_input'),
                  controller: controller,
                  selectAllOnFocus: false,
                ),
              ),
            ),
          ),
        ),
      );

      final finder = find.byKey(const ValueKey('credit_limit_input'));
      expect(finder, findsOneWidget);

      // Single tap on input
      await tester.tap(finder);
      await tester.pumpAndSettle();

      // Selection must remain collapsed, never selecting all text
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, equals(controller.selection.extentOffset));
      expect(controller.selection.baseOffset != -1, isTrue);
    });
  });
}
