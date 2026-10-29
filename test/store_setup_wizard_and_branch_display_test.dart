import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/first_branch_tutorial_carousel.dart';

void main() {
  group('Store Entity Branch Display Rules', () {
    test('single-store merchant has shouldShowBranch == false', () {
      const store = Store(
        id: 'store-1',
        name: 'Supermercado Central',
        branchName: 'Principal',
        logo: '/logo.png',
        status: 'ACTIVE',
        hasMultipleBranches: false,
      );

      expect(store.hasMultipleBranches, isFalse);
      expect(store.shouldShowBranch, isFalse);
      expect(store.branchLabel, isEmpty);
      expect(store.displayName, equals('Supermercado Central'));
    });

    test('multi-store merchant has shouldShowBranch == true and formatted label', () {
      const store = Store(
        id: 'store-1',
        name: 'Supermercado Central',
        branchName: 'Sede Chacao',
        logo: '/logo.png',
        status: 'ACTIVE',
        hasMultipleBranches: true,
      );

      expect(store.hasMultipleBranches, isTrue);
      expect(store.shouldShowBranch, isTrue);
      expect(store.branchLabel, equals('Sucursal Sede Chacao'));
      expect(store.combinedDisplayName, equals('Supermercado Central (Sucursal Sede Chacao)'));
      expect(store.displayName, equals('Sucursal Sede Chacao (Supermercado Central)'));
    });

    test('multi-store merchant with empty branchName has shouldShowBranch == false', () {
      const store = Store(
        id: 'store-1',
        name: 'Supermercado Central',
        branchName: '   ',
        logo: '/logo.png',
        status: 'ACTIVE',
        hasMultipleBranches: true,
      );

      expect(store.shouldShowBranch, isFalse);
      expect(store.branchLabel, isEmpty);
    });

    test('Store supports optional instagram and tiktok handles', () {
      const store = Store(
        id: 'store-1',
        name: 'Supermercado Central',
        branchName: 'Principal',
        logo: '/logo.png',
        status: 'ACTIVE',
        instagram: 'super_central',
        tiktok: 'supercentral_oficial',
      );

      expect(store.instagram, equals('super_central'));
      expect(store.tiktok, equals('supercentral_oficial'));
    });
  });

  group('Social Media Handle Sanitization', () {
    String? sanitizeHandle(String? raw) {
      if (raw == null) return null;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return trimmed.replaceAll(RegExp(r'^@+'), '').trim();
    }

    test('strips leading @ symbol and whitespace', () {
      expect(sanitizeHandle('  @tienda_oficial  '), equals('tienda_oficial'));
      expect(sanitizeHandle('@@doble_arroba'), equals('doble_arroba'));
      expect(sanitizeHandle('sin_arroba'), equals('sin_arroba'));
    });

    test('returns null for empty or whitespace-only values', () {
      expect(sanitizeHandle(''), isNull);
      expect(sanitizeHandle('   '), isNull);
      expect(sanitizeHandle(null), isNull);
    });
  });

  group('FirstBranchTutorialCarousel Widget Tests', () {
    testWidgets('renders first slide and advances with Siguiente', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FirstBranchTutorialCarousel(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      // Slide 1 is visible
      expect(find.text('Tu Negocio Crece a tu Ritmo'), findsOneWidget);
      expect(find.text('Saltar tutorial'), findsOneWidget);

      // Tap Siguiente to go to Slide 2
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('¿Tienes una Sola Tienda?'), findsOneWidget);

      // Tap Siguiente to go to Slide 3
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Tus Clientes Solo Ven tu Marca'), findsOneWidget);
      expect(find.text('¡Entendido, vamos a configurar! 🚀'), findsOneWidget);

      // Tap final button
      await tester.tap(find.text('¡Entendido, vamos a configurar! 🚀'));
      await tester.pump();

      expect(completed, isTrue);
    });

    testWidgets('skip action immediately invokes onComplete', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FirstBranchTutorialCarousel(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.text('Saltar tutorial'), findsOneWidget);
      await tester.tap(find.text('Saltar tutorial'));
      await tester.pump();

      expect(completed, isTrue);
    });
  });
}

