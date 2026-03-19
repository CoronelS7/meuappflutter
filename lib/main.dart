import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:meu_app_flutter/screens/splash.dart';
import 'package:meu_app_flutter/stripe/stripe_config.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureStripe();

  runApp(const MyApp());
}

Future<void> _configureStripe() async {
  if (StripeConfig.publishableKey.isEmpty) {
    return;
  }

  Stripe.publishableKey = StripeConfig.publishableKey;
  await Stripe.instance.applySettings();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pedido Facil',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const SplashScreen(),
    );
  }
}
