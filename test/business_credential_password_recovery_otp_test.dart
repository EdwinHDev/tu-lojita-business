import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/screens/login_screen.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

void main() {
  group('tu_lojita_business - ForgotPasswordScreen Widget Tests', () {
    testWidgets('Renders email request input, button, and prefilled email', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(initialEmail: 'negocio@empresa.com'),
          ),
        ),
      );

      // Verify header and description
      expect(find.text('Recuperar Contraseña'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('negocio@empresa.com'), findsOneWidget);
      expect(find.text('Enviar Código de Recuperación'), findsOneWidget);
    });

    testWidgets('Validates email field when empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      // Tap Enviar Código without entering email
      await tester.tap(find.text('Enviar Código de Recuperación'));
      await tester.pump();

      expect(find.text('Por favor ingresa tu correo electrónico'), findsOneWidget);
    });

    testWidgets('Displays interactive OTP input and paste button after requesting code', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeBusinessRecoveryAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(initialEmail: 'negocio@empresa.com'),
          ),
        ),
      );

      // Tap Enviar Código
      await tester.tap(find.text('Enviar Código de Recuperación'));
      await tester.pumpAndSettle();

      // Check OTP view header and description
      expect(find.text('Introduce el Código'), findsOneWidget);
      expect(find.textContaining('negocio@empresa.com'), findsOneWidget);

      // Check quick-action paste button
      expect(find.text('Pegar código del portapapeles'), findsOneWidget);
      expect(find.text('Verificar Código'), findsOneWidget);

      // Interactive TextField must be present with number keyboard
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, equals(TextInputType.number));
      expect(textField.autofillHints, contains(AutofillHints.oneTimeCode));

      // Enter 6 digits manually
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      // Verify digits are reflected visually
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });
  });

  group('tu_lojita_business - ResetPasswordScreen Widget Tests', () {
    testWidgets('Renders password fields and validates matching confirmation', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordScreen(
              resetSessionToken: 'mock-reset-session-token',
              email: 'tienda@empresa.com',
            ),
          ),
        ),
      );

      expect(find.text('Crea una Nueva Contraseña'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('Confirmar nueva contraseña'), findsOneWidget);
      expect(find.text('Restablecer Contraseña'), findsOneWidget);

      // Fill in mismatching passwords
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.first, '123456');
      await tester.enterText(textFields.last, '999888');
      await tester.tap(find.text('Restablecer Contraseña'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('Validates minimum password length', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordScreen(
              resetSessionToken: 'mock-reset-session-token',
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, '12');
      await tester.enterText(textFields.last, '12');
      await tester.tap(find.text('Restablecer Contraseña'));
      await tester.pump();

      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
    });
  });

  group('tu_lojita_business - LoginScreen Password Recovery Link Tests', () {
    testWidgets('Renders ¿Olvidaste tu contraseña? button and prefilled initialEmail', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(initialEmail: 'cuenta_recuperada@negocio.com'),
          ),
        ),
      );

      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(find.text('cuenta_recuperada@negocio.com'), findsOneWidget);
    });
  });
}

class _FakeBusinessRecoveryAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthInitial();

  @override
  Future<String?> requestForgotPasswordOtp(String email) async {
    return 'fake-business-recovery-token-123';
  }

  @override
  Future<String?> verifyForgotPasswordOtp({
    required String recoveryToken,
    required String otp,
  }) async {
    return 'fake-business-reset-session-token-456';
  }
}
