import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import 'stripe_config.dart';

class CheckoutException implements Exception {
  const CheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum CheckoutPaymentMethod { card, googlePay }

class CheckoutService {
  const CheckoutService();

  Future<bool> isGooglePaySupported() async {
    if (!StripeConfig.isStripeConfigured || !StripeConfig.isAndroid) {
      return false;
    }

    try {
      return await Stripe.instance.isPlatformPaySupported(
        googlePay: IsGooglePaySupportedParams(
          testEnv: StripeConfig.googlePayUsesTestEnvironment,
          existingPaymentMethodRequired: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> startCheckout({
    required String customerKey,
    required bool saveCard,
    required int amountInCents,
    required String description,
    required CheckoutPaymentMethod paymentMethod,
  }) async {
    final session = await _createPaymentIntent(
      customerKey: customerKey,
      saveCard: saveCard,
      amountInCents: amountInCents,
      description: description,
    );

    switch (paymentMethod) {
      case CheckoutPaymentMethod.card:
        await _startCardCheckout(session);
        return;
      case CheckoutPaymentMethod.googlePay:
        await _startGooglePayCheckout(session);
        return;
    }
  }

  Future<void> _startCardCheckout(_CheckoutSession session) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'Pedido Facil',
        paymentIntentClientSecret: session.clientSecret,
        customerId: session.customerId,
        customerEphemeralKeySecret: session.customerEphemeralKeySecret,
        style: ThemeMode.light,
        primaryButtonLabel: 'Pagar agora',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> _startGooglePayCheckout(_CheckoutSession session) async {
    if (!StripeConfig.isAndroid) {
      throw const CheckoutException(
        'Google Pay esta disponivel somente no Android neste app.',
      );
    }

    await Stripe.instance.confirmPlatformPayPaymentIntent(
      clientSecret: session.clientSecret,
      confirmParams: PlatformPayConfirmParams.googlePay(
        googlePay: GooglePayParams(
          merchantName: 'Pedido Facil',
          merchantCountryCode: StripeConfig.googlePayMerchantCountryCode,
          currencyCode: StripeConfig.googlePayCurrencyCode,
          testEnv: StripeConfig.googlePayUsesTestEnvironment,
          isEmailRequired: true,
        ),
      ),
    );
  }

  Future<_CheckoutSession> _createPaymentIntent({
    required String customerKey,
    required bool saveCard,
    required int amountInCents,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('${StripeConfig.backendBaseUrl}/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerKey': customerKey,
        'saveCard': saveCard,
        'amountInCents': amountInCents,
        'description': description,
      }),
    );

    final payload = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw CheckoutException(
        payload['error'] as String? ??
            'Nao foi possivel criar o PaymentIntent no backend.',
      );
    }

    final clientSecret = payload['clientSecret'] as String? ?? '';
    final customerId = payload['customerId'] as String? ?? '';
    final customerEphemeralKeySecret =
        payload['customerEphemeralKeySecret'] as String? ?? '';

    if (clientSecret.isEmpty ||
        customerId.isEmpty ||
        customerEphemeralKeySecret.isEmpty) {
      throw const CheckoutException(
        'O backend nao retornou todos os dados esperados do Stripe.',
      );
    }

    return _CheckoutSession(
      clientSecret: clientSecret,
      customerId: customerId,
      customerEphemeralKeySecret: customerEphemeralKeySecret,
    );
  }

  Map<String, Object?> _decodeJson(String source) {
    if (source.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }

    return const {};
  }
}

class _CheckoutSession {
  const _CheckoutSession({
    required this.clientSecret,
    required this.customerId,
    required this.customerEphemeralKeySecret,
  });

  final String clientSecret;
  final String customerId;
  final String customerEphemeralKeySecret;
}
