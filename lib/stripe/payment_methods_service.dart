import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'stripe_config.dart';

class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  factory SavedPaymentMethod.fromJson(Map<String, Object?> json) {
    return SavedPaymentMethod(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? 'card',
      last4: json['last4'] as String? ?? '0000',
      expMonth: json['expMonth'] as int? ?? 0,
      expYear: json['expYear'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  String get expiryLabel {
    final month = expMonth.toString().padLeft(2, '0');
    final year = expYear.toString().padLeft(4, '0');
    final shortYear = year.length >= 2 ? year.substring(year.length - 2) : year;
    return '$month/$shortYear';
  }
}

class CustomerSheetSession {
  const CustomerSheetSession({
    required this.customerId,
    required this.customerEphemeralKeySecret,
    required this.setupIntentClientSecret,
  });

  factory CustomerSheetSession.fromJson(Map<String, Object?> json) {
    return CustomerSheetSession(
      customerId: json['customerId'] as String? ?? '',
      customerEphemeralKeySecret:
          json['customerEphemeralKeySecret'] as String? ?? '',
      setupIntentClientSecret: json['setupIntentClientSecret'] as String? ?? '',
    );
  }

  final String customerId;
  final String customerEphemeralKeySecret;
  final String setupIntentClientSecret;
}

class PaymentMethodsException implements Exception {
  const PaymentMethodsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentMethodsService {
  const PaymentMethodsService();
  static const Duration _requestTimeout = Duration(seconds: 6);

  Future<List<SavedPaymentMethod>> listSavedCards({
    required String customerKey,
  }) async {
    final uri = Uri.parse(
      '${StripeConfig.backendBaseUrl}/payment-methods',
    ).replace(queryParameters: {'customerKey': customerKey});

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      throw const PaymentMethodsException(
        'A consulta dos cartoes demorou muito. Tente novamente.',
      );
    }

    final payload = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw PaymentMethodsException(
        payload['error'] as String? ??
            'Nao foi possivel carregar os cartoes salvos.',
      );
    }

    final rawMethods = payload['paymentMethods'];
    if (rawMethods is! List) {
      return const [];
    }

    return rawMethods
        .whereType<Map>()
        .map(
          (method) => SavedPaymentMethod.fromJson(
            Map<String, Object?>.from(method.cast<String, Object?>()),
          ),
        )
        .toList();
  }

  Future<CustomerSheetSession> createCustomerSheetSession({
    required String customerKey,
  }) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${StripeConfig.backendBaseUrl}/customer-sheet'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'customerKey': customerKey}),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const PaymentMethodsException(
        'A abertura do gerenciador de cartoes demorou muito.',
      );
    }

    final payload = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw PaymentMethodsException(
        payload['error'] as String? ??
            'Nao foi possivel abrir o gerenciador de cartoes.',
      );
    }

    final session = CustomerSheetSession.fromJson(payload);
    if (session.customerId.isEmpty ||
        session.customerEphemeralKeySecret.isEmpty ||
        session.setupIntentClientSecret.isEmpty) {
      throw const PaymentMethodsException(
        'O backend nao retornou os dados do CustomerSheet.',
      );
    }

    return session;
  }

  Map<String, Object?> _decodeJson(String source) {
    if (source.isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (_) {
      return const {};
    }

    return const {};
  }
}
