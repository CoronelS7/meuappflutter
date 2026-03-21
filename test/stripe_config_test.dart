import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_flutter/stripe/stripe_config.dart';

void main() {
  group('Stripe publishable key validation', () {
    test('accepts valid test key format', () {
      const key =
          'pk_test_51T7feJJKRPbMWbDHvcKll1DipZVEaqKylzmtQAsqdLUqrSrehE4t2epb2r0bP8hqBmPXtCh2cMQLUWfc3i0uIXxk00I65lDQ5F';
      expect(StripeConfig.isPublishableKeyValid(key), isTrue);
    });

    test('rejects placeholder key', () {
      const key = 'pk_test_SUA_CHAVE_AQUI';
      expect(StripeConfig.isPublishableKeyValid(key), isFalse);
    });

    test('rejects non publishable secret key', () {
      const key = 'sk_test_1234567890';
      expect(StripeConfig.isPublishableKeyValid(key), isFalse);
    });
  });
}
