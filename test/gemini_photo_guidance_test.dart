import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/gemini_photo_guidance_bottom_sheet.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/step_basic_info.dart';
import 'package:tu_lojita_business/features/store_ai/domain/entities/store_ai_models.dart';
import 'package:tu_lojita_business/features/store_ai/presentation/providers/store_ai_providers.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  const testUser = User(
    id: 'u-1',
    email: 'user@test.com',
    firstName: 'Carlos',
    lastName: 'Rivas',
    role: 'COMPANY_OWNER',
    hasCompany: true,
    company: Company(
      id: 'comp-1',
      name: 'Empresa Test',
      rif: 'J-12345678-0',
      logo: '/img/logo.png',
    ),
  );

  group('GeminiPhotoGuidanceBottomSheet', () {
    testWidgets('renders prompt text with square 1:1, 80%, white background',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => GeminiPhotoGuidanceBottomSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Mejora tus fotos gratis'), findsOneWidget);
      expect(find.byKey(const Key('gemini_guidance_copy_button')), findsOneWidget);
      expect(find.byKey(const Key('gemini_guidance_open_web_button')), findsOneWidget);

      // Verify prompt contains mandatory 1:1 square instructions
      expect(
        find.text(GeminiPhotoGuidanceBottomSheet.promptText),
        findsOneWidget,
      );
      expect(
        GeminiPhotoGuidanceBottomSheet.promptText,
        contains('1:1'),
      );
      expect(
        GeminiPhotoGuidanceBottomSheet.promptText,
        contains('cuadrado'),
      );
      expect(
        GeminiPhotoGuidanceBottomSheet.promptText,
        contains('80%'),
      );
      expect(
        GeminiPhotoGuidanceBottomSheet.promptText,
        contains('fondo blanco puro de estudio'),
      );
    });

    testWidgets('copy prompt copies to clipboard', (tester) async {
      String? clipboardData;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardData = (call.arguments as Map)['text'] as String?;
          return null;
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => GeminiPhotoGuidanceBottomSheet.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gemini_guidance_copy_button')));
      await tester.pumpAndSettle();

      expect(clipboardData, isNotNull);
      expect(clipboardData, contains('1:1'));
      expect(clipboardData, contains('cuadrado'));
      expect(clipboardData, contains('80%'));
    });
  });

  group('StepBasicInfo Gemini Guidance Chip', () {
    testWidgets('shows guidance chip when platform AI is disabled',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          platformAiGlobalEnabledProvider.overrideWith((ref) => false),
          authProvider.overrideWith(() => _StubAuthNotifier(testUser)),
          storeDetailsProvider.overrideWith(
            () => _StubStoreDetailsNotifier(aiEnabled: false),
          ),
          itemFormProvider.overrideWith(() => ItemFormNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StepBasicInfo(
                storeId: 'store-1',
                formKey: formKey,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('gemini_photo_guidance_chip')), findsOneWidget);
      expect(find.text('¿Quieres fotos profesionales gratis?'), findsOneWidget);

      // Tap chip and verify bottom sheet opens
      await tester.tap(find.byKey(const Key('gemini_photo_guidance_chip')));
      await tester.pumpAndSettle();

      expect(find.text('Mejora tus fotos gratis'), findsOneWidget);
    });

    testWidgets('hides guidance chip when native AI is enabled and available',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          platformAiGlobalEnabledProvider.overrideWith((ref) => true),
          authProvider.overrideWith(() => _StubAuthNotifier(testUser)),
          storeDetailsProvider.overrideWith(
            () => _StubStoreDetailsNotifier(aiEnabled: true),
          ),
          storeAiCatalogProvider('store-1').overrideWith(
            (ref) async => const StoreAiCatalog(
              storeId: 'store-1',
              available: true,
              globalEnabled: true,
              storeEnabled: true,
            ),
          ),
          itemFormProvider.overrideWith(() => ItemFormNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StepBasicInfo(
                storeId: 'store-1',
                formKey: formKey,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('gemini_photo_guidance_chip')), findsNothing);
    });
  });
}

class _StubAuthNotifier extends AuthNotifier {
  final User user;
  _StubAuthNotifier(this.user);

  @override
  AuthState build() => Authenticated(user);
}

class _StubStoreDetailsNotifier extends StoreDetailsNotifier {
  final bool aiEnabled;
  _StubStoreDetailsNotifier({required this.aiEnabled});

  @override
  StoreDetailsState build() {
    return StoreDetailsState(
      storeData: {
        'store-1': StoreDetailsData(
          store: Store(
            id: 'store-1',
            name: 'Sucursal Test',
            logo: '/img/logo.png',
            status: 'ACTIVE',
            aiEnabled: aiEnabled,
            companyId: 'comp-1',
          ),
          categories: const [],
        ),
      },
    );
  }

  @override
  Future<void> loadData(String storeId, {bool force = false}) async {}

  @override
  Future<void> refresh(String storeId) async {}
}
