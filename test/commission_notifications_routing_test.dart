import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
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

class _FakeAuthNotifier extends AuthNotifier {
  final User _user;
  _FakeAuthNotifier(this._user);

  @override
  AuthState build() => Authenticated(_user);
}

class _FakeStoresNotifier extends StoresNotifier {
  final StoresState _state;
  _FakeStoresNotifier(this._state);

  @override
  StoresState build() => _state;

  @override
  Future<void> loadData() async {}
}

class _FakeNotificationsNotifier extends NotificationsNotifier {
  final List<AppNotification> _items;
  _FakeNotificationsNotifier(this._items);

  @override
  Future<List<AppNotification>> build() async => _items;

  @override
  Future<void> loadNotifications() async {
    state = AsyncData(_items);
  }

  @override
  Future<void> markAsRead(String notificationId) async {}
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    await initializeDateFormatting('es');
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  const ownerUser = User(
    id: 'owner-1',
    email: 'owner@test.com',
    firstName: 'Edwin',
    lastName: 'Morales',
    role: 'COMPANY',
    isCollaborator: false,
  );

  const nonFinancialCollab = User(
    id: 'collab-ops',
    email: 'ops@test.com',
    firstName: 'Carlos',
    lastName: 'Ops',
    role: 'COLLABORATOR',
    isCollaborator: true,
    hasFullBranchAccess: true,
    permissions: ['orders:view'],
  );

  const branchStore = Store(
    id: 'store-c1',
    name: 'Tienda Sol',
    logo: '',
    status: 'SUSPENDED',
    productsCount: 5,
  );

  final notifications = [
    AppNotification(
      id: 'n-rem',
      title: 'Quedan 2 días (D-2) · Comisiones Tienda Sol',
      body: 'Saldo pendiente: \$ 20.00.',
      type: 'COMMISSION_DEBT_REMINDER',
      targetId: 'bill-1',
      storeId: 'store-c1',
      channelType: 'COMMISSION_DEBT',
      isRead: false,
      createdAt: DateTime.now(),
    ),
    AppNotification(
      id: 'n-rev',
      title: '¡Pago aprobado y tienda reactivada! · Tienda Sol',
      body: 'Tu tienda ya vuelve a estar activa.',
      type: 'COMMISSION_PAYMENT_REVIEWED',
      targetId: 'rep-1',
      storeId: 'store-c1',
      channelType: 'COMMISSION_DEBT',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 'n-susp',
      title: 'Tienda suspendida por deuda · Tienda Sol',
      body: 'Venció tu período de gracia.',
      type: 'STORE_SUSPENDED',
      targetId: 'store-c1',
      storeId: 'store-c1',
      channelType: 'COMMISSION_DEBT',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  testWidgets(
      'NotificationsScreen renders commission categories and routes taps to /dashboard/stores/:id/debts',
      (tester) async {
    final pushed = <String>[];
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/dashboard/stores/:storeId/debts',
          builder: (_, state) {
            pushed.add(state.uri.toString());
            return const Scaffold(body: Text('Debts Hub'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(ownerUser)),
          storesProvider.overrideWith(
            () => _FakeStoresNotifier(
              const StoresState(stores: [branchStore], isLoading: false),
            ),
          ),
          notificationsProvider
              .overrideWith(() => _FakeNotificationsNotifier(notifications)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('COMISIONES'), findsOneWidget);
    expect(find.text('PAGO COMISIÓN'), findsOneWidget);
    expect(find.text('MORA COMISIONES'), findsOneWidget);

    await tester.tap(find.text('Tienda suspendida por deuda · Tienda Sol'));
    await tester.pumpAndSettle();
    expect(pushed, ['/dashboard/stores/store-c1/debts']);
  });

  testWidgets(
      'NotificationsScreen blocks debt hub navigation when collaborator lacks financial permission',
      (tester) async {
    final pushed = <String>[];
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/dashboard/stores/:storeId/debts',
          builder: (_, state) {
            pushed.add(state.uri.toString());
            return const Scaffold(body: Text('Debts Hub'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider
              .overrideWith(() => _FakeAuthNotifier(nonFinancialCollab)),
          storesProvider.overrideWith(
            () => _FakeStoresNotifier(
              const StoresState(stores: [branchStore], isLoading: false),
            ),
          ),
          notificationsProvider
              .overrideWith(() => _FakeNotificationsNotifier([notifications.first])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quedan 2 días (D-2) · Comisiones Tienda Sol'));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);
  });
}
