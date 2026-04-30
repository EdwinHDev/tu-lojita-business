import 'package:flutter_dotenv/flutter_dotenv.dart';

class Envs {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'http://localhost:4500/api/v1');
  static String get googleServerClientId => dotenv.get('GOOGLE_SERVER_CLIENT_ID');
  static String get googleAndroidClientId => dotenv.get('GOOGLE_ANDROID_CLIENT_ID');
  static String get apiBaseUrlImages => dotenv.get('API_BASE_URL_IMAGES', fallback: 'http://localhost:4200');
  static String get apiKeyImages => dotenv.get('API_KEY_IMAGES');
}
