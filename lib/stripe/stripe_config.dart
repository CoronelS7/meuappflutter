import 'package:flutter/foundation.dart';

class StripeConfig {
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51T7feJJKRPbMWbDHvcKll1DipZVEaqKylzmtQAsqdLUqrSrehE4t2epb2r0bP8hqBmPXtCh2cMQLUWfc3i0uIXxk00I65lDQ5F',
  );

  static const backendUrlOverride = String.fromEnvironment(
    'STRIPE_BACKEND_URL',
  );

  static const cloudFunctionsBackendUrl = String.fromEnvironment(
    'STRIPE_CLOUD_FUNCTIONS_URL',
    defaultValue:
        'https://southamerica-east1-ecommerce-40890.cloudfunctions.net/stripeApi',
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

  static String get normalizedPublishableKey => publishableKey.trim();

  static bool isPublishableKeyValid(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) {
      return false;
    }

    final hasValidPrefix =
        key.startsWith('pk_test_') || key.startsWith('pk_live_');
    if (!hasValidPrefix) {
      return false;
    }

    final lower = key.toLowerCase();
    const placeholderTokens = <String>[
      'sua_chave',
      'cole_sua',
      'placeholder',
      'your_key',
      'yourkey',
      'example',
      'xxxx',
    ];

    for (final token in placeholderTokens) {
      if (lower.contains(token)) {
        return false;
      }
    }

    return key.length >= 32;
  }

  static String maskPublishableKey(String rawKey) {
    final key = rawKey.trim();
    if (key.isEmpty) {
      return '(vazia)';
    }

    if (key.length <= 18) {
      return key;
    }

    final start = key.substring(0, 12);
    final end = key.substring(key.length - 6);
    return '$start...$end (len ${key.length})';
  }

  static bool get isStripeConfigured =>
      isPublishableKeyValid(normalizedPublishableKey);

  static String get publishableKeyValidationMessage {
    if (normalizedPublishableKey.isEmpty) {
      return 'Defina STRIPE_PUBLISHABLE_KEY com uma chave publica da Stripe (pk_test_... ou pk_live_...).';
    }

    return 'STRIPE_PUBLISHABLE_KEY invalida. Use a chave publica real da Stripe (pk_test_... ou pk_live_...). Valor atual: ${maskPublishableKey(normalizedPublishableKey)}';
  }

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get googlePayUsesTestEnvironment {
    if (googlePayTestEnvOverride.isNotEmpty) {
      return googlePayTestEnvOverride.toLowerCase() == 'true';
    }

    return normalizedPublishableKey.startsWith('pk_test_');
  }

  static String get backendBaseUrl {
    if (backendUrlOverride.isNotEmpty) {
      return backendUrlOverride;
    }

    return cloudFunctionsBackendUrl;
  }
}
