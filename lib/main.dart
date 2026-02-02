import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pedido Fácil',

      // 🔤 Fonte definida AQUI para o app inteiro
      theme: ThemeData(fontFamily: 'Poppins'),

      home: const HomeScreen(),
    );
  }
}
