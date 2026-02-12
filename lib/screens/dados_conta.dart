import 'package:flutter/material.dart';

class DadosContaScreen extends StatelessWidget {
  const DadosContaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados da conta'),
      ),
      body: const Center(
        child: Text(
          'Tela de Dados da Conta',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
