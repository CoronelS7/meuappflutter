import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/products_repository.dart';
import 'package:meu_app_flutter/screens/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ProductsRepository _productsRepository = ProductsRepository();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final splashDelay = Future<void>.delayed(const Duration(seconds: 3));
    final preloadProducts = _productsRepository.preloadProducts().catchError((
      _,
    ) {
      return _productsRepository.cachedProducts;
    });

    await Future.wait([splashDelay, preloadProducts]);

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary400, AppColors.primary200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/imagens/logo.png', height: 204, width: 204),
          ],
        ),
      ),
    );
  }
}
