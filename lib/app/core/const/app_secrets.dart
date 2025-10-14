import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppSecrets {
  AppSecrets._();

  static String get publishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get secretKey =>
      dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.chys.app/api';

  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'https://api.chys.app';
}
