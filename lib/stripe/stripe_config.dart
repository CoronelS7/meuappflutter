import 'package:flutter/foundation.dart';

class StripeConfig {
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static const backendUrlOverride = String.fromEnvironment(
    'STRIPE_BACKEND_URL',
  );

  static String get backendBaseUrl {
    if (backendUrlOverride.isNotEmpty) {
      return backendUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:4242';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4242';
    }

    return 'http://localhost:4242';
  }
}
