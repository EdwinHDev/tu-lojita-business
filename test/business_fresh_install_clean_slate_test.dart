import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fresh Install Clean Slate Tests (Business App)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'old_expired_access_token',
        'refresh_token': 'old_expired_refresh_token',
        'user_data': '{"id":"old_business_user"}',
      });
    });

    test('ensureCleanInstall wipes residual Keychain / SecureStorage on first run', () async {
      const storage = FlutterSecureStorage();
      final localAuth = LocalAuthDataSourceImpl(storage);

      // Verify old values exist prior to clean install check
      final tokenBefore = await storage.read(key: 'access_token');
      expect(tokenBefore, equals('old_expired_access_token'));

      // Run clean install detection
      await localAuth.ensureCleanInstall();

      // Verify all leftover keys were purged
      final tokenAfter = await storage.read(key: 'access_token');
      final refreshAfter = await storage.read(key: 'refresh_token');
      expect(tokenAfter, isNull);
      expect(refreshAfter, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('business_app_has_run_before'), isTrue);
    });

    test('ensureCleanInstall does not wipe tokens on subsequent launches', () async {
      const storage = FlutterSecureStorage();
      final localAuth = LocalAuthDataSourceImpl(storage);

      // First run: clears and marks has_run_before
      await localAuth.ensureCleanInstall();

      // User logs in and stores active tokens
      await localAuth.saveAccessToken('new_valid_access_token');
      await localAuth.saveRefreshToken('new_valid_refresh_token');

      // Subsequent app launch
      await localAuth.ensureCleanInstall();

      // Verify active tokens remain intact
      final token = await localAuth.getAccessToken();
      expect(token, equals('new_valid_access_token'));
    });
  });
}
