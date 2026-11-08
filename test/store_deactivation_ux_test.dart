import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_details_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/branch_lifecycle_dialogs.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_list_tile.dart';
import 'package:tu_lojita_business/features/ranking/presentation/providers/ranking_providers.dart';
import 'package:tu_lojita_business/features/ranking/domain/entities/ranking_models.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class FakeAuthNotifier extends AuthNotifier {
  final User user;
  FakeAuthNotifier(this.user);

  @override
  AuthState build() => Authenticated(user);
}

class FakeStoreSettingsNotifier extends StoreSettingsNotifier {
  final Store store;
  FakeStoreSettingsNotifier(this.store);

  @override
  StoreSettingsState build() => StoreSettingsState(store: store, isLoading: false);

  @override
  Future<void> loadStore(String storeId) async {}
}

class FakeStoreDetailsNotifier extends StoreDetailsNotifier {
  final Store store;
  FakeStoreDetailsNotifier(this.store);

  @override
  StoreDetailsState build() => StoreDetailsState(
        storeData: {
          store.id: StoreDetailsData(store: store, isLoading: false),
        },
        isLoading: false,
      );

  @override
  Future<void> loadData(String storeId, {bool force = false}) async {}

  @override
  Future<void> refresh(String storeId) async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.test.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.test.com\n',
    );
  });

  const dummyOwner = User(
    id: 'user-1',
    email: 'owner@test.com',
    firstName: 'Dueño',
    lastName: 'Test',
    role: 'OWNER',
    isCollaborator: false,
  );

  const activeStore = Store(
    id: 'store-1',
    name: 'Boutique Elegance',
    logo: '',
    status: 'ACTIVE',
    productsCount: 15,
  );

  const inactiveStore = Store(
    id: 'store-2',
    name: 'Zapatería Central',
    logo: '',
    status: 'INACTIVE',
    productsCount: 8,
  );

  group('Store Deactivation UX & Warning Tests', () {
    testWidgets(
        'BranchLifecycleOtpDialog displays public visibility warning when actionType is DEACTIVATE',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BranchLifecycleOtpDialog(
              storeId: 'store-1',
              branchName: 'Zapatería Central',
              actionType: 'DEACTIVATE',
              initialEmail: 'owner@test.com',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Desactivar Tienda'), findsOneWidget);
      expect(
        find.textContaining('Al desactivar tu tienda, esta y todos sus artículos quedarán ocultos al público'),
        findsOneWidget,
      );
      expect(find.text('Desactivar'), findsOneWidget);

      // Tap cancel to cleanly trigger dispose and cancel the 60s timer
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });

    testWidgets('StoreListTile displays "Desactivada" badge for inactive store',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreListTile(
              store: inactiveStore,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Desactivada'), findsOneWidget);
      expect(find.text('Pausada'), findsNothing);
    });

    testWidgets('StoreListTile displays "Activa" badge for active store',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreListTile(
              store: activeStore,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Activa'), findsOneWidget);
    });

    testWidgets(
        'StoreDetailsScreen displays prominent "Desactivada" badge and warning banner when store is inactive',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => FakeAuthNotifier(dummyOwner)),
            storeDetailsProvider.overrideWith(() => FakeStoreDetailsNotifier(inactiveStore)),
            storeRankingProvider('store-2').overrideWith((ref) => Completer<StoreRankingData>().future),
          ],
          child: const MaterialApp(
            home: StoreDetailsScreen(storeId: 'store-2'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Desactivada'), findsWidgets);
      expect(
        find.textContaining('Esta tienda está desactivada. Ni la tienda ni sus artículos son visibles para los clientes.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'StoreSettingsScreen lifecycle buttons render cleanly without overflow on narrow 320px viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => FakeAuthNotifier(dummyOwner)),
            storeSettingsProvider.overrideWith(() => FakeStoreSettingsNotifier(activeStore)),
          ],
          child: const MaterialApp(
            home: StoreSettingsScreen(storeId: 'store-1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final deactivateBtn = find.text('Desactivar Tienda');
      await tester.scrollUntilVisible(deactivateBtn, 300);
      await tester.pumpAndSettle();

      expect(deactivateBtn, findsOneWidget);
      expect(find.text('Eliminar Tienda'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
