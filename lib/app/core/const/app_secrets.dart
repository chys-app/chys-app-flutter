import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppSecrets {
  static const String _publishableKeyName = 'STRIPE_PUBLISHABLE_KEY';
  static const String _secretKeyName = 'STRIPE_SECRET_KEY';

  static String get publishableKey => _resolve(_publishableKeyName);

  static String get secretKey => _resolve(_secretKeyName);

  static String _resolve(String key) {
    final dotenvValue = dotenv.env[key];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue;
    }

    final defineValue = key == _publishableKeyName
        ? const String.fromEnvironment(_publishableKeyName, defaultValue: '')
        : const String.fromEnvironment(_secretKeyName, defaultValue: '');

    if (defineValue.isNotEmpty) {
      return defineValue;
    }

    developer.log(
      'Secret for $key is missing. Ensure it is provided via .env or --dart-define.',
      name: 'AppSecrets',
      level: 900,
    );
    return '';
  }
}
