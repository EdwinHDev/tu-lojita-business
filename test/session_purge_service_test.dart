import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tu_lojita_business/core/services/session_purge_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_notifier.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_state.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Store createDummyStore(String id, String branchName) {
    return Store(
      id: id,
      name: 'Empresa Demo',
      branchName: branchName,
      logo: 'https://example.com/logo.png',
      status: 'ACTIVE',
      phone: '04121234567',
    );
  }

  Item createDummyItem(String id, String title) {
    return Item(
      id: id,
      title: title,
      description: 'Descripción de prueba',
      price: 15.0,
      mainImage: 'https://example.com/item.png',
      images: const [],
      isFeatured: false,
      itemType: ItemType.product,
      trackInventory: false,
      requiresBooking: false,
    );
  }

  group('SessionPurgeService Tests (Business App)', () {
    setUpAll(() {
      dotenv.loadFromString(
        envString:
            'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
      );
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'test_merchant_token',
        'refresh_token': 'test_merchant_refresh_token',
        'user_data': '{"id":"merchant_1","email":"merchant@test.com"}',
      });
    });

    test('purge() cleanly resets stores, analytics, item catalog, socket and secure storage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify tokens exist in storage
      final localAuth = container.read(localAuthDataSourceProvider);
      expect(await localAuth.getAccessToken(), equals('test_merchant_token'));

      // Seed state into storesProvider
      final storesNotifier = container.read(storesProvider.notifier);
      final dummyStore = createDummyStore('store_123', 'Sucursal Principal');
      storesNotifier.state = StoresState(stores: [dummyStore]);
      expect(container.read(storesProvider).stores.length, equals(1));

      // Seed state into dashboardAnalyticsProvider
      final analyticsNotifier = container.read(dashboardAnalyticsProvider.notifier);
      analyticsNotifier.setPeriod('month');
      expect(container.read(dashboardAnalyticsProvider).selectedPeriod, equals('month'));

      // Seed state into itemListProvider
      final itemNotifier = container.read(itemListProvider.notifier);
      final dummyItem = createDummyItem('item_1', 'Hamburguesa Especial');
      itemNotifier.state = ItemListState(
        storeData: {
          'store_123': ItemListData(items: [dummyItem]),
        },
      );
      expect(container.read(itemListProvider).forStore('store_123').items.length, equals(1));

      // Register store in SocketService
      final socketService = container.read(socketServiceProvider);
      socketService.joinStore('store_123');

      // Execute full session purge
      final purgeService = container.read(sessionPurgeServiceProvider);
      await purgeService.purge();

      // Verify notifiers return to initial empty state
      expect(container.read(storesProvider).stores, isEmpty);
      expect(container.read(itemListProvider).forStore('store_123').items, isEmpty);
      expect(container.read(dashboardAnalyticsProvider).analytics, isNull);

      // Verify secure storage is wiped
      expect(await localAuth.getAccessToken(), isNull);
      expect(await localAuth.getRefreshToken(), isNull);
      await Future.delayed(Duration.zero);
    });

    test('Explicit reset() methods immediately clear notifiers to initial state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // StoresNotifier reset
      final storesNotifier = container.read(storesProvider.notifier);
      storesNotifier.state = StoresState(stores: [
        createDummyStore('store_999', 'Sucursal Centro'),
      ]);
      expect(container.read(storesProvider).stores.length, equals(1));
      storesNotifier.reset();
      expect(container.read(storesProvider).stores, isEmpty);

      // DashboardAnalyticsNotifier reset
      final analyticsNotifier = container.read(dashboardAnalyticsProvider.notifier);
      analyticsNotifier.setPeriod('year');
      analyticsNotifier.reset();
      expect(container.read(dashboardAnalyticsProvider).selectedPeriod, equals('month'));

      // ItemListNotifier reset
      final itemNotifier = container.read(itemListProvider.notifier);
      itemNotifier.state = ItemListState(
        storeData: {
          'store_999': ItemListData(
            items: [createDummyItem('item_x', 'Pizza Margarita')],
          ),
        },
      );
      expect(container.read(itemListProvider).forStore('store_999').items.length, equals(1));
      itemNotifier.reset();
      expect(container.read(itemListProvider).forStore('store_999').items, isEmpty);
      await Future.delayed(Duration.zero);
    });
  });
}
