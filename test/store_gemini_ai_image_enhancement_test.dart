import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import 'package:tu_lojita_business/features/dashboard/data/models/store_model.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_settings_screen.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_owner_stats.dart';
import 'package:tu_lojita_business/features/items/domain/entities/property_template.dart';
import 'package:tu_lojita_business/features/items/domain/repositories/item_repository.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/wizard/step_basic_info.dart';
import 'package:tu_lojita_business/features/store_ai/domain/entities/store_ai_models.dart';
import 'package:tu_lojita_business/features/store_ai/domain/repositories/store_ai_repository.dart';
import 'package:tu_lojita_business/features/store_ai/presentation/providers/store_ai_providers.dart';
import 'widget_test.dart';

// Minimal 1x1 transparent PNG
final Uint8List _kOnePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  group('User.canUseStoreAi authorization rules', () {
    const company = Company(
      id: 'comp-1',
      name: 'Inversiones Demo C.A.',
      rif: 'J-12345678-9',
      logo: '/img/company.png',
    );

    test('company owner can use AI in any company store', () {
      const owner = User(
        id: 'u-owner',
        email: 'owner@demo.com',
        firstName: 'Ana',
        lastName: 'Pérez',
        role: 'COMPANY_OWNER',
        hasCompany: true,
        company: company,
      );

      expect(owner.canUseStoreAi('store-a'), isTrue);
      expect(owner.canUseStoreAi('store-b'), isTrue);
    });

    test('independent vendor without company cannot use AI', () {
      const independentVendor = User(
        id: 'u-vendor',
        email: 'vendor@demo.com',
        firstName: 'Luis',
        lastName: 'Gómez',
        role: 'VENDOR',
        hasCompany: false,
      );

      expect(independentVendor.canUseStoreAi('store-a'), isFalse);
    });

    test(
      'collaborator requires branch access, inventory:edit, and storeId in aiAllowedStoreIds',
      () {
        const authorizedCollab = User(
          id: 'collab-1',
          email: '',
          firstName: 'Marta',
          lastName: 'Rojas',
          role: 'COLLABORATOR',
          hasCompany: true,
          company: company,
          isCollaborator: true,
          permissions: ['inventory:edit'],
          allowedBranchIds: ['store-a', 'store-b'],
          aiAllowedStoreIds: ['store-a'],
        );

        expect(authorizedCollab.canUseStoreAi('store-a'), isTrue);
        expect(authorizedCollab.canUseStoreAi('store-b'), isFalse);
        expect(authorizedCollab.canUseStoreAi('store-c'), isFalse);

        final withoutInventoryEdit = authorizedCollab.copyWith(
          permissions: ['orders:view'],
        );
        expect(withoutInventoryEdit.canUseStoreAi('store-a'), isFalse);
      },
    );
  });

  group('StoreModel & StoreAi domain models', () {
    test('parses StoreModel aiEnabled and nested company.id', () {
      final store = StoreModel.fromJson({
        'id': 'store-1',
        'name': 'Tienda Centro',
        'logo': '/img/logo.png',
        'status': 'ACTIVE',
        'aiEnabled': true,
        'company': {'id': 'comp-99'},
      });

      expect(store.aiEnabled, isTrue);
      expect(store.companyId, 'comp-99');
    });

    test('parses StoreAiCatalog and AiEnhancedImageResult', () {
      final catalog = StoreAiCatalog.fromJson({
        'storeId': 'store-1',
        'available': true,
        'globalEnabled': true,
        'storeEnabled': true,
        'officialPresets': [
          {
            'id': 'preset-1',
            'title': 'Estudio Blanco',
            'description': 'Fondo blanco puro',
            'prompt': 'White studio background',
          },
        ],
        'storePrompts': [
          {
            'id': 'sp-1',
            'title': 'Mármol Cálido',
            'prompt': 'Warm marble surface',
          },
        ],
        'dailyLimit': 50,
        'remainingDailyQuota': 47,
      });

      expect(catalog.available, isTrue);
      expect(catalog.officialPresets.single.title, 'Estudio Blanco');
      expect(catalog.storePrompts.single.title, 'Mármol Cálido');
      expect(catalog.remainingDailyQuota, 47);

      final result = AiEnhancedImageResult.fromJson({
        'mimeType': 'image/png',
        'imageBase64': base64Encode(_kOnePixelPng),
        'remainingDailyQuota': 46,
      });
      expect(result.bytes, isNotEmpty);
      expect(result.remainingDailyQuota, 46);
    });
  });

  group('ItemFormNotifier.replaceImageWithEnhanced', () {
    test('replaces local selected file and remaps existing image cleanly', () async {
      final tempDir = await Directory.systemTemp.createTemp('ai_test_');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      final localOriginal = File('${tempDir.path}/orig.png')
        ..writeAsBytesSync(_kOnePixelPng);
      final localEnhanced = File('${tempDir.path}/enh_local.png')
        ..writeAsBytesSync(_kOnePixelPng);
      final existingEnhanced = File('${tempDir.path}/enh_existing.png')
        ..writeAsBytesSync(_kOnePixelPng);

      final container = ProviderContainer(
        overrides: [
          itemRepositoryProvider.overrideWithValue(_StubItemRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(itemFormProvider.notifier);
      notifier.initFromItem(
        const Item(
          id: 'item-1',
          title: 'Zapatos',
          description: 'Zapatos deportivos de prueba',
          basePrice: 40,
          price: 40,
          mainImage: '/img/old-1.jpg',
          images: ['/img/old-1.jpg', '/img/old-2.jpg'],
          isFeatured: false,
          itemType: ItemType.product,
          trackInventory: true,
          stockQuantity: 5,
          requiresBooking: false,
          hasVariants: true,
          variants: [
            ItemVariant(
              axisValues: {'Talla': '40'},
              imageUrl: '/img/old-1.jpg',
              stockQuantity: 5,
            ),
          ],
        ),
      );
      notifier.addImages([localOriginal]);
      notifier.setPrimaryImage(0);

      // 1. Replace local image (combinedIndex = 2)
      notifier.replaceImageWithEnhanced(2, localEnhanced);
      var current = container.read(itemFormProvider);
      expect(current.selectedImages.single.path, localEnhanced.path);
      expect(current.primaryImageIndex, 0);

      // 2. Replace first existing image (combinedIndex = 0)
      notifier.replaceImageWithEnhanced(0, existingEnhanced);
      current = container.read(itemFormProvider);
      expect(current.existingImages, ['/img/old-2.jpg']);
      expect(current.deletedImages, ['/img/old-1.jpg']);
      expect(current.selectedImages.length, 2);
      expect(current.selectedImages.last.path, existingEnhanced.path);
      // Combined index of newly appended enhanced image is 1 (existing) + 2 - 1 = 2
      expect(current.primaryImageIndex, 2);
      expect(current.variants.single.imageUrl, 'img_idx:2');
    });
  });

  group('StepBasicInfo AI badge visibility', () {
    const sampleItemWithPhoto = Item(
      id: 'item-w-1',
      title: 'Bolso Cuero',
      description: 'Bolso artesanal de cuero genuino',
      basePrice: 55,
      price: 55,
      mainImage: '/img/sample.jpg',
      images: ['/img/sample.jpg'],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: true,
      stockQuantity: 3,
      requiresBooking: false,
    );

    testWidgets(
      'shows "Mejorar con IA" only on loaded photos when eligible, never without base photo',
      (tester) async {
        const storeId = 'store-ai-1';
        final formKey = GlobalKey<FormState>();

        final container = ProviderContainer(
          overrides: [
            platformAiGlobalEnabledProvider.overrideWith((ref) => true),
            authProvider.overrideWith(() => _StubAuthNotifier(
                  const User(
                    id: 'collab-ok',
                    email: '',
                    firstName: 'Carlos',
                    lastName: 'Ruiz',
                    role: 'COLLABORATOR',
                    hasCompany: true,
                    isCollaborator: true,
                    permissions: ['inventory:edit'],
                    allowedBranchIds: [storeId],
                    aiAllowedStoreIds: [storeId],
                  ),
                )),
            storeDetailsProvider.overrideWith(
              () => _StubStoreDetailsNotifier(aiEnabled: true),
            ),
            storeAiRepositoryProvider.overrideWithValue(
              _StubStoreAiRepository(available: true),
            ),
            itemRepositoryProvider.overrideWithValue(_StubItemRepository()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: StepBasicInfo(storeId: storeId, formKey: formKey),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // With 0 photos loaded, there MUST NOT be any "Mejorar con IA" button
        expect(find.text('Mejorar con IA'), findsNothing);

        // Once a photo is loaded, "Mejorar con IA" appears on the thumbnail
        container
            .read(itemFormProvider.notifier)
            .initFromItem(sampleItemWithPhoto);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Mejorar con IA'), findsOneWidget);
      },
    );

    testWidgets(
      'hides "Mejorar con IA" when collaborator is not authorized for AI in that branch',
      (tester) async {
        const storeId = 'store-ai-1';
        final formKey = GlobalKey<FormState>();

        final container = ProviderContainer(
          overrides: [
            platformAiGlobalEnabledProvider.overrideWith((ref) => true),
            authProvider.overrideWith(() => _StubAuthNotifier(
                  const User(
                    id: 'collab-no-ai',
                    email: '',
                    firstName: 'Pedro',
                    lastName: 'Díaz',
                    role: 'COLLABORATOR',
                    hasCompany: true,
                    isCollaborator: true,
                    permissions: ['inventory:edit'],
                    allowedBranchIds: [storeId],
                    aiAllowedStoreIds: [],
                  ),
                )),
            storeDetailsProvider.overrideWith(
              () => _StubStoreDetailsNotifier(aiEnabled: true),
            ),
            storeAiRepositoryProvider.overrideWithValue(
              _StubStoreAiRepository(available: true),
            ),
            itemRepositoryProvider.overrideWithValue(_StubItemRepository()),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(itemFormProvider.notifier)
            .initFromItem(sampleItemWithPhoto);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: StepBasicInfo(storeId: storeId, formKey: formKey),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Mejorar con IA'), findsNothing);
      },
    );

    testWidgets(
      'hides "Mejorar con IA" when platformAiGlobalEnabledProvider is false',
      (tester) async {
        const storeId = 'store-ai-1';
        final formKey = GlobalKey<FormState>();

        final container = ProviderContainer(
          overrides: [
            platformAiGlobalEnabledProvider.overrideWith(
              (ref) => false,
            ),
            authProvider.overrideWith(() => _StubAuthNotifier(
                  const User(
                    id: 'collab-ok',
                    email: '',
                    firstName: 'Carlos',
                    lastName: 'Ruiz',
                    role: 'COLLABORATOR',
                    hasCompany: true,
                    isCollaborator: true,
                    permissions: ['inventory:edit'],
                    allowedBranchIds: [storeId],
                    aiAllowedStoreIds: [storeId],
                  ),
                )),
            storeDetailsProvider.overrideWith(
              () => _StubStoreDetailsNotifier(aiEnabled: true),
            ),
            storeAiRepositoryProvider.overrideWithValue(
              _StubStoreAiRepository(available: true),
            ),
            itemRepositoryProvider.overrideWithValue(_StubItemRepository()),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(itemFormProvider.notifier)
            .initFromItem(sampleItemWithPhoto);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: StepBasicInfo(storeId: storeId, formKey: formKey),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Mejorar con IA'), findsNothing);
      },
    );

    testWidgets(
      'tapping "Mejorar con IA" when platform goes disabled revalidates and shows suspended notification',
      (tester) async {
        const storeId = 'store-ai-1';
        final formKey = GlobalKey<FormState>();
        var globalAiState = true;

        final container = ProviderContainer(
          overrides: [
            platformAiGlobalEnabledProvider.overrideWith((ref) => globalAiState),
            authProvider.overrideWith(() => _StubAuthNotifier(
                  const User(
                    id: 'collab-ok',
                    email: '',
                    firstName: 'Carlos',
                    lastName: 'Ruiz',
                    role: 'COLLABORATOR',
                    hasCompany: true,
                    isCollaborator: true,
                    permissions: ['inventory:edit'],
                    allowedBranchIds: [storeId],
                    aiAllowedStoreIds: [storeId],
                  ),
                )),
            storeDetailsProvider.overrideWith(
              () => _StubStoreDetailsNotifier(aiEnabled: true),
            ),
            storeAiRepositoryProvider.overrideWithValue(
              _StubStoreAiRepository(available: true),
            ),
            itemRepositoryProvider.overrideWithValue(_StubItemRepository()),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(itemFormProvider.notifier)
            .initFromItem(sampleItemWithPhoto);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: StepBasicInfo(storeId: storeId, formKey: formKey),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Mejorar con IA'), findsOneWidget);

        // Platform admin disables global AI while screen is still open
        globalAiState = false;

        // User taps "Mejorar con IA"
        await tester.tap(find.text('Mejorar con IA'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // The button has disappeared from the screen
        expect(find.text('Mejorar con IA'), findsNothing);
      },
    );
  });

  group('StoreSettingsScreen AI tile visibility', () {
    const testStore = Store(
      id: 'store-1',
      name: 'Mi Tienda',
      logo: '/img/logo.png',
      status: 'ACTIVE',
      companyId: 'comp-1',
      aiEnabled: true,
    );

    const ownerUser = User(
      id: 'owner-1',
      email: 'owner@demo.com',
      firstName: 'Ana',
      lastName: 'Pérez',
      role: 'COMPANY_OWNER',
      hasCompany: true,
      company: Company(
        id: 'comp-1',
        name: 'Inversiones Demo C.A.',
        rif: 'J-12345678-9',
        logo: '/img/company.png',
      ),
    );

    testWidgets(
      'hides "Estudio Fotográfico IA" when platformAiGlobalEnabledProvider is false',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            platformAiGlobalEnabledProvider.overrideWith(
              (ref) => false,
            ),
            authProvider.overrideWith(() => _StubAuthNotifier(ownerUser)),
            storeSettingsProvider.overrideWith(
              () => _StubStoreSettingsNotifier(store: testStore),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StoreSettingsScreen(storeId: 'store-1'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Estudio Fotográfico IA'), findsNothing);
      },
    );

    testWidgets(
      'shows "Estudio Fotográfico IA" when platformAiGlobalEnabledProvider is true and user is owner',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            platformAiGlobalEnabledProvider.overrideWith(
              (ref) => true,
            ),
            authProvider.overrideWith(() => _StubAuthNotifier(ownerUser)),
            storeSettingsProvider.overrideWith(
              () => _StubStoreSettingsNotifier(store: testStore),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StoreSettingsScreen(storeId: 'store-1'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Estudio Fotográfico IA'), findsOneWidget);
      },
    );
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
        'store-ai-1': StoreDetailsData(
          store: Store(
            id: 'store-ai-1',
            name: 'Sucursal Principal',
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

class _StubStoreAiRepository implements StoreAiRepository {
  final bool available;
  _StubStoreAiRepository({required this.available});

  @override
  Future<StoreAiCatalog> getCatalog(String storeId) async {
    return StoreAiCatalog(
      storeId: storeId,
      available: available,
      globalEnabled: available,
      storeEnabled: available,
      officialPresets: const [
        OfficialAiPreset(
          id: 'p1',
          title: 'Estudio Blanco',
          prompt: 'Fondo blanco',
        ),
      ],
    );
  }

  @override
  Future<StoreAiSettings> getSettings(String storeId) =>
      throw UnimplementedError();

  @override
  Future<StoreAiKeyTestResult> testKey(
    String storeId, {
    required String apiKey,
    bool saveIfValid = true,
  }) =>
      throw UnimplementedError();

  @override
  Future<StoreAiSettings> updateSettings(
    String storeId, {
    bool? isEnabled,
    int? dailyLimit,
    List<StoreSavedPrompt>? customPrompts,
  }) =>
      throw UnimplementedError();

  @override
  Future<StoreAiSettings> deleteKey(String storeId) =>
      throw UnimplementedError();

  @override
  Future<AiEnhancedImageResult> enhanceImage(
    String storeId, {
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
    String? presetId,
    String? storePromptId,
    String? customPrompt,
  }) =>
      throw UnimplementedError();
}

class _StubItemRepository implements ItemRepository {
  @override
  Future<List<PropertyTemplate>> getCategoryTemplates(String categoryId) async =>
      [];

  @override
  Future<Item> createItem(
    Map<String, dynamic> itemData,
    List<File> images, {
    int mainImageIndex = 0,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteImages(List<String> imageUrls) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<Item> getItemById(String id) => throw UnimplementedError();

  @override
  Future<ItemOwnerStats> getItemOwnerStats(String id) async =>
      const ItemOwnerStats();

  @override
  Future<List<Item>> getItemsByStore(String storeId) async => [];

  @override
  Future<({List<Item> items, int total})> getItemsPaginated({
    required String storeId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    String? categoryId,
    String? sortBy,
    String? order,
    bool? onlyInStock,
  }) async =>
      (items: <Item>[], total: 0);

  @override
  Future<Item> updateItem(
    String id,
    Map<String, dynamic> itemData, {
    List<File>? newImages,
    int mainImageIndex = 0,
  }) =>
      throw UnimplementedError();
}

class _StubStoreSettingsNotifier extends StoreSettingsNotifier {
  final Store? store;
  _StubStoreSettingsNotifier({this.store});

  @override
  StoreSettingsState build() {
    return StoreSettingsState.initial().copyWith(
      store: store,
      isLoading: false,
    );
  }

  @override
  Future<void> loadStore(String storeId) async {}
}
