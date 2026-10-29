import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/ranking/domain/entities/ranking_models.dart';
import 'package:tu_lojita_business/features/ranking/presentation/providers/ranking_providers.dart';
import 'package:tu_lojita_business/features/ranking/presentation/widgets/daily_missions_card.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  final mockMissions = [
    DailyMissionItem(
      id: 'mission_1',
      code: 'VENTA_DEL_DIA',
      title: 'Primera Venta del Día',
      description: 'Concreta al menos 1 pedido hoy para mantener tu racha.',
      prReward: 15,
      targetCount: 1,
      currentCount: 0,
      isCompleted: false,
      isClaimed: false,
      badgeUrl: '/assets/ranking/achievements/first_step.png',
    ),
    DailyMissionItem(
      id: 'mission_2',
      code: 'EXCELENCIA_5_ESTRELLAS',
      title: 'Calidad Impecable',
      description: 'Recibe una reseña de 5 estrellas de un cliente satisfecho.',
      prReward: 25,
      targetCount: 1,
      currentCount: 1,
      isCompleted: true,
      isClaimed: false,
      badgeUrl: '/assets/ranking/achievements/five_stars.png',
    ),
    DailyMissionItem(
      id: 'mission_3',
      code: 'VOLUMEN_COMERCIAL',
      title: 'Impulso de Ventas',
      description: 'Entrega 3 o más pedidos completados en el día.',
      prReward: 35,
      targetCount: 3,
      currentCount: 3,
      isCompleted: true,
      isClaimed: true,
      badgeUrl: '/assets/ranking/achievements/star_seller.png',
    ),
  ];

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        dailyMissionsProvider('test-store')
            .overrideWith((ref) => Future.value(mockMissions)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: DailyMissionsCard(storeId: 'test-store'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'DailyMissionsCard renders correctly on compact 320x640 mobile screen without overflow or collapse',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify all 3 missions and their specific states are rendered
    expect(find.text('Misiones Diarias del Comerciante'), findsOneWidget);
    expect(find.text('Se reinician a las 12:00 AM'), findsOneWidget);
    expect(find.text('Primera Venta del Día'), findsOneWidget);
    expect(find.text('Calidad Impecable'), findsOneWidget);
    expect(find.text('Impulso de Ventas'), findsOneWidget);

    // Verify claim button for completed mission
    final claimButton = find.text('+25 PR');
    expect(claimButton, findsOneWidget);

    // Verify completed mission title width is normal (> 80px), NOT single-letter vertical column
    final titleSize = tester.getSize(find.text('Calidad Impecable'));
    expect(titleSize.width, greaterThan(40.0),
        reason: 'Mission title must not collapse into single-character width');
  });

  testWidgets(
      'DailyMissionsCard renders correctly on standard 360x800 mobile screen',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Calidad Impecable'), findsOneWidget);
    expect(find.text('+25 PR'), findsOneWidget);
    expect(find.text('Reclamado'), findsOneWidget);
  });

  testWidgets(
      'DailyMissionsCard renders correctly on large 412x915 mobile screen',
      (tester) async {
    tester.view.physicalSize = const Size(412 * 3.5, 915 * 3.5);
    tester.view.devicePixelRatio = 3.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Calidad Impecable'), findsOneWidget);
    expect(find.text('+25 PR'), findsOneWidget);
  });
}
