import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/notification.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/notifications_screen.dart';
import 'widget_test.dart';

class _MockAuthNotifier extends AuthNotifier {
  final User _mockUser;
  _MockAuthNotifier(this._mockUser);

  @override
  AuthState build() => Authenticated(_mockUser);
}

class _FakeNotificationsNotifier extends NotificationsNotifier {
  final List<AppNotification> items;
  _FakeNotificationsNotifier(this.items);

  @override
  Future<List<AppNotification>> build() async => items;

  @override
  Future<void> loadNotifications() async {
    state = AsyncData(items);
  }

  @override
  Future<void> markAsRead(String id) async {}
}

class _FakeStoresNotifier extends StoresNotifier {
  final List<Store> storeList;
  _FakeStoresNotifier(this.storeList);

  @override
  StoresState build() => StoresState(stores: storeList);

  @override
  Future<void> loadData() async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.test.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.test.com\n',
    );
  });

  const dummyStore = Store(
    id: 'store-123',
    name: 'Mi Tienda Test',
    branchName: 'Principal',
    logo: '/logo.png',
    status: 'ACTIVE',
  );

  const dummyUser = User(
    id: 'user-1',
    email: 'comercio@test.com',
    firstName: 'Admin',
    lastName: 'Comercio',
    role: 'OWNER',
    isCollaborator: false,
  );

  testWidgets('Tapping ACHIEVEMENT_UNLOCKED notification navigates immediately without modal hangs',
      (tester) async {
    final notification = AppNotification(
      id: 'notif-ach-1',
      title: '¡Logro Desbloqueado! 🏆',
      body: 'Tu tienda ha obtenido el logro "Primeros Pasos". ¡Ganaste +50 LP!',
      type: 'ACHIEVEMENT_UNLOCKED',
      targetId: 'ach-id-123',
      storeId: 'store-123',
      isRead: false,
      createdAt: DateTime.now(),
    );

    Map<String, dynamic>? capturedExtra;
    bool reachedCelebration = false;

    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/dashboard/ranking/achievement-unlocked',
          builder: (context, state) {
            reachedCelebration = true;
            capturedExtra = state.extra as Map<String, dynamic>?;
            return const Scaffold(
              body: Center(child: Text('CELEBRATION_SCREEN_REACHED')),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(dummyUser)),
          storesProvider.overrideWith(() => _FakeStoresNotifier([dummyStore])),
          notificationsProvider.overrideWith(() => _FakeNotificationsNotifier([notification])),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Validar que la notificación está visible
    expect(find.text('¡Logro Desbloqueado! 🏆'), findsOneWidget);

    // Tocar la notificación
    await tester.tap(find.text('¡Logro Desbloqueado! 🏆'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Validar que se navegó inmediatamente a la pantalla de logro
    expect(reachedCelebration, isTrue);
    expect(find.text('CELEBRATION_SCREEN_REACHED'), findsOneWidget);

    // Validar que los argumentos extra fueron extraídos fielmente del payload
    expect(capturedExtra, isNotNull);
    expect(capturedExtra!['achievementTitle'], equals('Primeros Pasos'));
    expect(capturedExtra!['lpBonus'], equals(50));
    expect(capturedExtra!['badgeUrl'], contains('first_step.png'));
    expect(capturedExtra!['storeId'], equals('store-123'));

    // Validar que NO existe ningún diálogo modal bloqueante en la pantalla
    expect(find.byType(Dialog), findsNothing);
  });
}
