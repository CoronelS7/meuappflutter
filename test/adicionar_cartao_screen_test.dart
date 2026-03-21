import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_flutter/screens/adicionar_cartao.dart';

void main() {
  group('AdicionarCartaoScreen', () {
    test('exige setupIntentClientSecret na criacao da tela', () {
      const screen = AdicionarCartaoScreen(
        setupIntentClientSecret: 'seti_test_client_secret',
      );

      expect(screen.setupIntentClientSecret, 'seti_test_client_secret');
    });
  });
}
