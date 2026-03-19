import 'package:flutter/foundation.dart';

class StripeConfig {
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static const backendUrlOverride = String.fromEnvironment(
    'STRIPE_BACKEND_URL',
  );

  static const googlePayMerchantCountryCode = String.fromEnvironment(
    'STRIPE_GOOGLE_PAY_COUNTRY_CODE',
    defaultValue: 'BR',
  );

  static const googlePayCurrencyCode = String.fromEnvironment(
    'STRIPE_GOOGLE_PAY_CURRENCY_CODE',
    defaultValue: 'BRL',
  );

  static const googlePayTestEnvOverride = String.fromEnvironment(
    'STRIPE_GOOGLE_PAY_TEST_ENV',
  );

  static bool get isStripeConfigured => publishableKey.isNotEmpty;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get googlePayUsesTestEnvironment {
    if (googlePayTestEnvOverride.isNotEmpty) {
      return googlePayTestEnvOverride.toLowerCase() == 'true';
    }

    return publishableKey.startsWith('pk_test_');
  }

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
