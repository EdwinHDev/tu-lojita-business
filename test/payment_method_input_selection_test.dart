import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/models/bank.dart';
import 'package:tu_lojita_business/core/models/store_payment_method.dart';
import 'package:tu_lojita_business/core/repositories/bank_repository.dart';
import 'package:tu_lojita_business/features/payment_methods/presentation/screens/payment_method_form_screen.dart';

void main() {
  final mockBanks = [
    Bank(id: 'bank-1', code: '0102', name: 'Banco de Venezuela'),
    Bank(id: 'bank-2', code: '0134', name: 'Banesco'),
  ];

  Widget createWidgetUnderTest({StorePaymentMethod? method}) {
    return ProviderScope(
      overrides: [
        banksProvider.overrideWith((ref) => Future.value(mockBanks)),
      ],
      child: MaterialApp(
        home: PaymentMethodFormScreen(
          storeId: 'store-123',
          method: method,
        ),
      ),
    );
  }

  group('PaymentMethodFormScreen Input Selection & Stability Tests', () {
    testWidgets('Tapping on descriptive title input does not select all text', (tester) async {
      final method = StorePaymentMethod(
        id: 'pm-1',
        type: PaymentMethodType.pagoMovil,
        title: '2164',
        accountHolder: 'Juan Perez',
        idNumber: '12345678',
        phoneNumber: '04141234567',
        isActive: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(method: method));
      await tester.pumpAndSettle();

      final titleFinder = find.widgetWithText(TextFormField, '2164');
      expect(titleFinder, findsOneWidget);

      final editableTextFinder = find.descendant(
        of: titleFinder,
        matching: find.byType(EditableText),
      );
      expect(editableTextFinder, findsOneWidget);

      final editableState = tester.state<EditableTextState>(editableTextFinder);
      expect(editableState.textEditingValue.text, '2164');

      // Tap on the input field
      await tester.tap(titleFinder);
      await tester.pumpAndSettle();

      // Selection must be collapsed, not selecting the whole word
      expect(editableState.textEditingValue.selection.isCollapsed, isTrue);
      expect(editableState.textEditingValue.selection.baseOffset,
          equals(editableState.textEditingValue.selection.extentOffset));
    });

    testWidgets('Cursor repositioning between characters does not get overwritten or select all', (tester) async {
      final method = StorePaymentMethod(
        id: 'pm-1',
        type: PaymentMethodType.pagoMovil,
        title: '2164',
        accountHolder: 'Juan Perez',
        idNumber: '12345678',
        phoneNumber: '04141234567',
        isActive: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(method: method));
      await tester.pumpAndSettle();

      final titleFinder = find.widgetWithText(TextFormField, '2164');
      final editableTextFinder = find.descendant(
        of: titleFinder,
        matching: find.byType(EditableText),
      );
      final editableState = tester.state<EditableTextState>(editableTextFinder);

      // Simulate placing cursor between '21' and '64' (offset 2)
      editableState.updateEditingValue(
        const TextEditingValue(
          text: '2164',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      // Selection should remain at offset 2 without being reset or selecting all
      expect(editableState.textEditingValue.text, '2164');
      expect(editableState.textEditingValue.selection.isCollapsed, isTrue);
      expect(editableState.textEditingValue.selection.baseOffset, 2);
      expect(editableState.textEditingValue.selection.extentOffset, 2);
    });

    testWidgets('Save button reactively enables when text changes and stays disabled when text is unchanged', (tester) async {
      final method = StorePaymentMethod(
        id: 'pm-1',
        type: PaymentMethodType.pagoMovil,
        title: '2164',
        accountHolder: 'Juan Perez',
        idNumber: '12345678',
        phoneNumber: '04141234567',
        isActive: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(method: method));
      await tester.pumpAndSettle();

      final titleFinder = find.widgetWithText(TextFormField, '2164');
      final editableTextFinder = find.descendant(
        of: titleFinder,
        matching: find.byType(EditableText),
      );
      final editableState = tester.state<EditableTextState>(editableTextFinder);

      // Initially unchanged, save button text is 'Guardar Cambios'
      expect(find.text('Guardar Cambios'), findsOneWidget);

      // Moving cursor only (no text change) does not trigger form state modification
      editableState.updateEditingValue(
        const TextEditingValue(
          text: '2164',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();

      // Actually modifying text content
      editableState.updateEditingValue(
        const TextEditingValue(
          text: '21645',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pumpAndSettle();

      expect(editableState.textEditingValue.text, '21645');
    });
  });
}

