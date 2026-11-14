import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/store_settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/branch_lifecycle_dialogs.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_details/store_scheduled_deletion_card.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  final User user;
  _FakeAuthNotifier(this.user);

  @override
  AuthState build() => Authenticated(user);
}

class _FakeStoreSettingsNotifier extends StoreSettingsNotifier {
  final Store store;
  _FakeStoreSettingsNotifier(this.store);

  @override
  StoreSettingsState build() =>
      StoreSettingsState(store: store, isLoading: false);

  @override
  Future<void> loadStore(String storeId) async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
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

  group('Store Lifecycle Suspension & Debt Locks UI', () {
    testWidgets(
      'StoreSettingsScreen renders Suspendida status, locks actions, and disables deletion on SUSPENDED branch',
      (tester) async {
        const suspendedStore = Store(
          id: 'store-susp',
          name: 'Tienda Demo',
          branchName: 'Sede Norte',
          logo: '',
          status: 'SUSPENDED',
          hasMultipleBranches: true,
          commissionDebt: 45.0,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _FakeAuthNotifier(dummyOwner)),
              storeSettingsProvider
                  .overrideWith(() => _FakeStoreSettingsNotifier(suspendedStore)),
            ],
            child: const MaterialApp(
              home: StoreSettingsScreen(storeId: 'store-susp'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final badgeFinder = find.text('Suspendida');
        await tester.scrollUntilVisible(badgeFinder, 300);
        await tester.pumpAndSettle();

        expect(badgeFinder, findsOneWidget);
        expect(find.text('Activa'), findsNothing);
        expect(find.text('Reactivar Sucursal'), findsNothing);
        expect(find.text('Desactivar Sucursal'), findsNothing);
        expect(
          find.text('Operaciones bloqueadas por suspensión'),
          findsOneWidget,
        );

        final deleteText = find.text('Eliminar Sucursal');
        await tester.scrollUntilVisible(deleteText, 200);
        await tester.pumpAndSettle();
        final deleteBtn = tester.widget<OutlinedButton>(
          find.ancestor(of: deleteText, matching: find.byType(OutlinedButton)),
        );
        expect(deleteBtn.onPressed, isNull);
      },
    );

    testWidgets(
      'StoreSettingsScreen disables deactivation and deletion when ACTIVE branch has pending commission debt',
      (tester) async {
        const indebtedStore = Store(
          id: 'store-debt',
          name: 'Tienda Deuda',
          branchName: 'Sede Sur',
          logo: '',
          status: 'ACTIVE',
          hasMultipleBranches: true,
          commissionDebt: 22.5,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _FakeAuthNotifier(dummyOwner)),
              storeSettingsProvider
                  .overrideWith(() => _FakeStoreSettingsNotifier(indebtedStore)),
            ],
            child: const MaterialApp(
              home: StoreSettingsScreen(storeId: 'store-debt'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final deactivateText = find.text('Desactivar Sucursal');
        await tester.scrollUntilVisible(deactivateText, 300);
        await tester.pumpAndSettle();

        expect(find.textContaining('22.50'), findsOneWidget);

        final deactivateBtn = tester.widget<OutlinedButton>(
          find.ancestor(
            of: deactivateText,
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(deactivateBtn.onPressed, isNull);

        final deleteText = find.text('Eliminar Sucursal');
        final deleteBtn = tester.widget<OutlinedButton>(
          find.ancestor(of: deleteText, matching: find.byType(OutlinedButton)),
        );
        expect(deleteBtn.onPressed, isNull);
      },
    );

    testWidgets(
      'StoreScheduledDeletionCard warns and hides reactivation promise for suspended or indebted branch',
      (tester) async {
        final scheduledDate = DateTime.now().add(const Duration(days: 5));
        final lockedDeletingStore = Store(
          id: 'store-del-lock',
          name: 'Tienda Bloqueada',
          branchName: 'Principal',
          logo: '',
          status: 'SUSPENDED',
          commissionDebt: 15.0,
          deletionScheduledAt: scheduledDate,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: StoreScheduledDeletionCard(
                  store: lockedDeletingStore,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Cancelar Eliminación'), findsOneWidget);
        expect(find.text('Cancelar Eliminación y Reactivar'), findsNothing);
        expect(
          find.textContaining('NO la reactivará: permanecerá Suspendida'),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancelar Eliminación'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('la sucursal permanecerá Suspendida y no se reactivará'),
          findsOneWidget,
        );
        expect(find.text('Sí, cancelar eliminación'), findsOneWidget);
        expect(find.text('Sí, reactivar'), findsNothing);
      },
    );

    testWidgets(
      'StoreScheduledDeletionCard keeps reactivation label on clean debt-free inactive branch',
      (tester) async {
        final scheduledDate = DateTime.now().add(const Duration(days: 4));
        final cleanDeletingStore = Store(
          id: 'store-del-clean',
          name: 'Tienda Limpia',
          logo: '',
          status: 'INACTIVE',
          commissionDebt: 0,
          deletionScheduledAt: scheduledDate,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: StoreScheduledDeletionCard(
                  store: cleanDeletingStore,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Cancelar Eliminación y Reactivar'), findsOneWidget);
      },
    );

    testWidgets(
      'BranchPreflightBlockersDialog displays suspension and debt blockers cleanly',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BranchPreflightBlockersDialog(
                branchName: 'Sede Norte',
                actionTitle: 'eliminar',
                blockers: [
                  'Esta sucursal se encuentra suspendida por la plataforma.',
                  'Esta sucursal posee una deuda acumulada de comisiones.',
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('requisitos y obligaciones pendientes'),
          findsOneWidget,
        );
        expect(
          find.text('Esta sucursal se encuentra suspendida por la plataforma.'),
          findsOneWidget,
        );
        expect(
          find.text('Esta sucursal posee una deuda acumulada de comisiones.'),
          findsOneWidget,
        );
      },
    );
  });
}
