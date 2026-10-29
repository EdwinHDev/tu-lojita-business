import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/ranking/domain/entities/ranking_models.dart';
import 'package:tu_lojita_business/features/ranking/presentation/providers/ranking_providers.dart';
import 'package:tu_lojita_business/features/ranking/presentation/screens/my_ranking_screen.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  testWidgets('MyRankingScreen renders both tabs without layout overflows or exceptions',
      (tester) async {
    final List<FlutterErrorDetails> errors = [];
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      FlutterError.dumpErrorToConsole(details);
    };

    // Standard Android mobile screen size (360 x 800 logical px)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRanking = StoreRankingData(
      storeId: 'test-store',
      division: 'PUESTO_AMBULANTE',
      divisionTitle: 'Puesto Ambulante',
      divisionEmblemUrl: '/assets/ranking/emblems/ambulante.png',
      currentLp: 100,
      currentPR: 100,
      lifetimeLp: 100,
      ordersCompletedCount: 5,
      inCalibration: false,
      flaggedForReview: false,
      position: 1,
      consecutiveSalesDays: 1,
      streakMultiplier: 1.0,
      isShieldActive: true,
      inDangerZone: false,
      showcase: [
        AchievementItem(
          id: '5d0963fb-b6ef-4ecd-9016-c700d5d3de59',
          code: 'Perfil Dorado',
          title: 'Perfil Dorado',
          description: 'Completa el perfil de tu tienda con logo, banner y descripción.',
          badgeUrl: '/assets/ranking/achievements/gold_profile.png',
          triggerType: 'PROFILE_COMPLETE',
          triggerThreshold: 1,
          lpBonus: 50,
          isUnlocked: true,
          inShowcase: true,
        ),
      ],
    );

    final mockAchievements = [
      AchievementItem(
        id: '44c097fa-6bf9-4dfd-91c8-2c8cd9bf2b1d',
        code: 'Reputación Impecable',
        title: 'Reputación Impecable',
        description: 'Consigue 10 reseñas de 5 estrellas de compradores satisfechos.',
        badgeUrl: '/assets/ranking/achievements/five_stars.png',
        triggerType: 'REVIEW_5_STAR_COUNT',
        triggerThreshold: 10,
        lpBonus: 100,
        isUnlocked: false,
      ),
      AchievementItem(
        id: '943c1fb1-63c2-469f-b9dc-cffc5c9f5e9e',
        code: 'Primeros Pasos',
        title: 'Primeros Pasos',
        description: 'Completa tu primera orden exitosa en la plataforma.',
        badgeUrl: '/assets/ranking/achievements/first_step.png',
        triggerType: 'ORDER_COUNT',
        triggerThreshold: 1,
        lpBonus: 25,
        isUnlocked: false,
      ),
      AchievementItem(
        id: 'db4c3f5b-d4cd-4c8d-82c0-28e699afab4a',
        code: 'Vendedor Estrella',
        title: 'Vendedor Estrella',
        description: 'Completa 10 órdenes exitosas.',
        badgeUrl: '/assets/ranking/achievements/star_seller.png',
        triggerType: 'ORDER_COUNT',
        triggerThreshold: 10,
        lpBonus: 50,
        isUnlocked: false,
      ),
      AchievementItem(
        id: '3fa46e33-5671-4bd2-a4f0-8a47c7f7ebe3',
        code: 'Centurión del Comercio',
        title: 'Centurión del Comercio',
        description: 'Completa 100 órdenes exitosas.',
        badgeUrl: '/assets/ranking/achievements/centurion.png',
        triggerType: 'ORDER_COUNT',
        triggerThreshold: 100,
        lpBonus: 200,
        isUnlocked: false,
      ),
      AchievementItem(
        id: '8337ebc1-8912-4683-bae2-73f2bc4d522c',
        code: 'Paz y Salvo',
        title: 'Paz y Salvo',
        description: 'Mantén tu tienda durante 30 días sin ninguna disputa abierta.',
        badgeUrl: '/assets/ranking/achievements/no_disputes.png',
        triggerType: 'NO_DISPUTES_DAYS',
        triggerThreshold: 30,
        lpBonus: 50,
        isUnlocked: false,
      ),
      AchievementItem(
        id: '5d0963fb-b6ef-4ecd-9016-c700d5d3de59',
        code: 'Perfil Dorado',
        title: 'Perfil Dorado',
        description: 'Completa el perfil de tu tienda con logo, banner y descripción.',
        badgeUrl: '/assets/ranking/achievements/gold_profile.png',
        triggerType: 'PROFILE_COMPLETE',
        triggerThreshold: 1,
        lpBonus: 50,
        isUnlocked: true,
        inShowcase: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeRankingProvider('test-store')
              .overrideWith((ref) => Future.value(mockRanking)),
          storeEventsProvider('test-store')
              .overrideWith((ref) => Future.value([])),
          storeAchievementsProvider('test-store')
              .overrideWith((ref) => Future.value(mockAchievements)),
          dailyMissionsProvider('test-store')
              .overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MyRankingScreen(storeId: 'test-store'),
        ),
      ),
    );

    // Initial frame and async provider resolution
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Tab 1 is displayed
    expect(find.text('Misiones & PR'), findsOneWidget);
    expect(find.text('Logros & Vitrina'), findsOneWidget);

    // Switch to Tab 2 (Logros & Vitrina)
    await tester.tap(find.text('Logros & Vitrina'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Tab 2 elements render properly
    expect(find.text('Vitrina de la Tienda'), findsOneWidget);
    expect(find.text('Todos los Logros'), findsOneWidget);
    expect(find.text('Perfil Dorado'), findsAtLeastNWidgets(1));

    // Scroll down to reveal achievement cards in the grid
    final scrollableFinder = find.byType(SingleChildScrollView);
    if (scrollableFinder.evaluate().isNotEmpty) {
      await tester.drag(scrollableFinder.last, const Offset(0, -350), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Test tapping the showcase item button (toggle inShowcase)
    final showcaseButton = find.text('★ Vitrina');
    if (showcaseButton.evaluate().isNotEmpty) {
      await tester.tap(showcaseButton.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Ensure zero layout overflows or exceptions were captured
    expect(errors, isEmpty,
        reason: 'Expected 0 RenderFlex overflow or layout errors');
  });
}
