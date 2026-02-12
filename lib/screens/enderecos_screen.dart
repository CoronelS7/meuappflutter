import 'package:flutter/material.dart';

class EnderecosScreen extends StatelessWidget {
  const EnderecosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endereços'),
      ),
      body: const Center(
        child: Text(
          'Tela de Endereços',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
