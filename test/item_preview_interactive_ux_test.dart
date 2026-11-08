import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_category.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/step_item_preview.dart';
import 'widget_test.dart';

class _MockStoreDetailsNotifier extends StoreDetailsNotifier {
  @override
  StoreDetailsState build() {
    return const StoreDetailsState(
      storeData: {
        'test-store-123': StoreDetailsData(
          categories: [
            StoreCategory(
              id: 'cat-1',
              name: 'Ropa Casual',
              description: 'Prendas y accesorios casuales',
            ),
          ],
        ),
      },
    );
  }
}

class _TestItemFormNotifier extends ItemFormNotifier {
  final ItemFormState initialState;
  _TestItemFormNotifier(this.initialState);

  @override
  ItemFormState build() => initialState;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  const testStoreId = 'test-store-123';

  testWidgets(
      'StepItemPreview respects variant stock limit and prevents stepper from exceeding stock',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testState = ItemFormState(
      title: 'Camisa Polo Oxford',
      description: 'Camisa polo elegante',
      price: 30.0,
      trackInventory: true,
      hasVariants: true,
      variantAxes: [
        VariantAxis(name: 'Color', values: ['Azul Navy', 'Rojo']),
      ],
      variants: [
        ItemVariant(
          id: 'var-1',
          axisValues: {'Color': 'Azul Navy'},
          price: 30.0,
          stockQuantity: 2.0, // Limit is 2
          isActive: true,
        ),
        ItemVariant(
          id: 'var-2',
          axisValues: {'Color': 'Rojo'},
          price: 30.0,
          stockQuantity: 5.0,
          isActive: true,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeDetailsProvider.overrideWith(() => _MockStoreDetailsNotifier()),
          itemFormProvider.overrideWith(() => _TestItemFormNotifier(testState)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StepItemPreview(storeId: testStoreId),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify product title is shown
    expect(find.text('Camisa Polo Oxford'), findsOneWidget);

    // Initial variant selection: find "+" buttons for row steppers
    final addButtons = find.byIcon(Icons.add_rounded);
    expect(addButtons, findsWidgets);

    // Tap "+" on first variant (Azul Navy, limit 2)
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    // Variant quantity is now 1
    expect(find.text('1 seleccionado'), findsOneWidget);

    // Tap "+" again -> quantity becomes 2 (reaches max stock)
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('2 seleccionados'), findsOneWidget);

    // Tap "+" a 3rd time -> should be blocked by stock limit of 2!
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    // Verify quantity remains 2 and does not increment to 3
    expect(find.text('2 seleccionados'), findsOneWidget);
    expect(find.text('3 seleccionados'), findsNothing);

    // Verify subtotal reflects exactly 2 * 30.0 = $60.00
    expect(find.text('\$60.00'), findsWidgets);
  });

  testWidgets(
      'StepItemPreview displays interactive customization groups and excludes buy button',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testState = ItemFormState(
      title: 'Hamburguesa Artesanal',
      description: 'Hamburguesa con papas',
      price: 10.0,
      trackInventory: false,
      hasVariants: false,
      customizationGroups: [
        CustomizationGroup(
          id: 'grp-sauce',
          name: 'Salsas Extras',
          minSelect: 0,
          maxSelect: 3,
          options: [
            CustomizationOption(
              id: 'opt-bbq',
              name: 'Salsa BBQ',
              price: 1.5,
              defaultQuantity: 0,
              minQuantity: 0,
              maxQuantity: 2,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeDetailsProvider.overrideWith(() => _MockStoreDetailsNotifier()),
          itemFormProvider.overrideWith(() => _TestItemFormNotifier(testState)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StepItemPreview(storeId: testStoreId),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify customization group is rendered with client app style
    expect(find.text('Personalización'), findsOneWidget);
    expect(find.text('Salsas Extras'), findsOneWidget);
    expect(find.text('Salsa BBQ'), findsOneWidget);
    expect(find.text('+ \$1.50'), findsOneWidget);

    // Initial total is base price $10.00
    expect(find.text('\$10.00'), findsWidgets);

    // 2. Tap "+" on Salsa BBQ option
    final addOptionBtn = find.byIcon(Icons.add_circle_outline);
    expect(addOptionBtn, findsOneWidget);
    await tester.tap(addOptionBtn);
    await tester.pumpAndSettle();

    // Count is now 1
    expect(find.text('1'), findsWidgets);

    // Total price is reactively updated to $10.00 + $1.50 = $11.50
    expect(find.text('\$11.50'), findsOneWidget);

    // 3. Verify NO buy button or "Agregar al Carrito" exists in preview
    expect(find.textContaining('Agregar al Carrito'), findsNothing);
    expect(find.text('Total estimado en vista previa'), findsOneWidget);
  });

  testWidgets(
      'StepItemPreview availability badge shows urgency warning only when single variant remaining has stock <= 3',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Multiple variants with low stock -> should NOT show "¡Apurate!"
    const multiVariantState = ItemFormState(
      title: 'Zapatillas Running',
      description: 'Zapatillas deportivas',
      price: 50.0,
      trackInventory: true,
      hasVariants: true,
      variantAxes: [
        VariantAxis(name: 'Color', values: ['Negro', 'Blanco']),
      ],
      variants: [
        ItemVariant(
          id: 'v-1',
          axisValues: {'Color': 'Negro'},
          price: 50.0,
          stockQuantity: 2.0,
          isActive: true,
        ),
        ItemVariant(
          id: 'v-2',
          axisValues: {'Color': 'Blanco'},
          price: 50.0,
          stockQuantity: 2.0,
          isActive: true,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeDetailsProvider.overrideWith(() => _MockStoreDetailsNotifier()),
          itemFormProvider.overrideWith(() => _TestItemFormNotifier(multiVariantState)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StepItemPreview(storeId: testStoreId),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Since there are 2 available variants, urgency warning is NOT triggered
    expect(find.textContaining('¡Apurate, solo quedan'), findsNothing);
    expect(find.text('En stock (2 disponibles)'), findsOneWidget);
  });
}

