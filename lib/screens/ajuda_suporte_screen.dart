import 'package:flutter/material.dart';

class AjudaSuporteScreen extends StatelessWidget {
  const AjudaSuporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
      ),
      body: const Center(
        child: Text(
          'Tela de Ajuda e Suporte',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
