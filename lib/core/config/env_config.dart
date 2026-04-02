import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get googleServerClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  static String get googleAndroidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ?? '';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? '';

  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'Tu Lojita';
}
