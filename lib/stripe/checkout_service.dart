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

class CheckoutService {
  const CheckoutService();

  Future<void> startCheckout({
    required String customerKey,
    required bool saveCard,
    required int amountInCents,
    required String description,
  }) async {
    final session = await _createPaymentIntent(
      customerKey: customerKey,
      saveCard: saveCard,
      amountInCents: amountInCents,
      description: description,
    );

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
