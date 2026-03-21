import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_flutter/screens/adicionar_cartao.dart';

void main() {
  Widget buildTestApp() {
    return const MaterialApp(home: AdicionarCartaoScreen());
  }

  group('AdicionarCartaoScreen', () {
    testWidgets('formata numero do cartao e validade', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));

      await tester.enterText(fields.at(1), '4242424242424242');
      await tester.enterText(fields.at(2), '1230');
      await tester.pump();

      expect(find.text('4242 4242 4242 4242'), findsOneWidget);
      expect(find.text('12/30'), findsOneWidget);
    });

    testWidgets('fecha o teclado ao tocar fora do campo', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final firstField = find.byType(TextFormField).first;
      await tester.tap(firstField);
      await tester.pump();

      expect(tester.testTextInput.hasAnyClients, isTrue);

      await tester.tapAt(const Offset(20, 500));
      await tester.pump();

      expect(tester.testTextInput.hasAnyClients, isFalse);
    });

    testWidgets('mostra validacoes ao tentar salvar sem dados', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Salvar cartao'));
      await tester.pump();

      expect(find.text('Informe o nome no cartao'), findsOneWidget);
      expect(find.text('Informe o numero do cartao'), findsOneWidget);
      expect(find.text('Informe a validade'), findsOneWidget);
      expect(find.text('CVV invalido'), findsOneWidget);
    });
  });
}
