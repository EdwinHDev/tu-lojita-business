import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/data/models/user_model.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/settings_screen.dart';

void main() {
  group('tu_lojita_business - User isCredentialUser discrimination', () {
    test('User without googleId is identified as credential user', () {
      const user = User(
        id: 'merchant-1',
        email: 'merchant@example.com',
        firstName: 'Carlos',
        lastName: 'Comercio',
        role: 'COMPANY',
        googleId: null,
      );

      expect(user.isCredentialUser, isTrue);
    });

    test('User with valid googleId is identified as OAuth user (NOT credential)', () {
      const user = User(
        id: 'merchant-2',
        email: 'merchant.oauth@gmail.com',
        firstName: 'Google',
        lastName: 'Merchant',
        role: 'COMPANY',
        googleId: '1029384756',
      );

      expect(user.isCredentialUser, isFalse);
    });

    test('UserModel.fromJson parses googleId properly', () {
      final jsonCred = {
        'id': 'b-cred-1',
        'email': 'cred@business.com',
        'firstName': 'Business',
        'lastName': 'Owner',
        'role': 'COMPANY',
      };
      final modelCred = UserModel.fromJson(jsonCred);
      expect(modelCred.isCredentialUser, isTrue);
      expect(modelCred.googleId, isNull);

      final jsonOAuth = {
        'id': 'b-oauth-1',
        'email': 'oauth@business.com',
        'firstName': 'Google',
        'lastName': 'Owner',
        'role': 'COMPANY',
        'googleId': '5544332211',
      };
      final modelOAuth = UserModel.fromJson(jsonOAuth);
      expect(modelOAuth.isCredentialUser, isFalse);
      expect(modelOAuth.googleId, equals('5544332211'));
    });
  });

  group('tu_lojita_business SettingsScreen - Selective Cambiar Contraseña visibility', () {
    testWidgets('Renders Cambiar Contraseña for credential users', (tester) async {
      const credentialUser = User(
        id: 'cred-merchant',
        email: 'cred@merchant.com',
        firstName: 'Pedro',
        lastName: 'Comerciante',
        role: 'COMPANY',
        googleId: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeAuthNotifier(credentialUser)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cambiar Contraseña'), findsOneWidget);
    });

    testWidgets('DOES NOT render Cambiar Contraseña for Google OAuth users', (tester) async {
      const oauthUser = User(
        id: 'oauth-merchant',
        email: 'oauth@gmail.com',
        firstName: 'Google',
        lastName: 'Comerciante',
        role: 'COMPANY',
        googleId: '9988776655',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => _FakeAuthNotifier(oauthUser)),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cambiar Contraseña'), findsNothing);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final User _initialUser;
  _FakeAuthNotifier(this._initialUser);

  @override
  AuthState build() {
    return Authenticated(_initialUser);
  }
}
