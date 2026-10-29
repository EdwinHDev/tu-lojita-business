import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/splash_screen.dart';
import 'widget_test.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.tulojita.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.tulojita.com\n',
    );
  });

  testWidgets('SplashScreen renders clean animated logo and dynamic feedback without layout exceptions',
      (tester) async {
    final List<FlutterErrorDetails> errors = [];
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
      FlutterError.dumpErrorToConsole(details);
    };

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify initial feedback status text is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify that obsolete circular container and redundant text headers are NOT present
    expect(find.text('Tu Lojita'), findsNothing);
    expect(find.text('EMPRESAS & NEGOCIOS'), findsNothing);

    // Verify transitions are present for logo animation
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ScaleTransition), findsWidgets);

    // Pump animation forward
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    expect(errors, isEmpty);
  });
}
