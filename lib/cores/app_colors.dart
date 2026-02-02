import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // impede instanciar a classe

  static const Color primary100 = Color(0xFF8DFFD4);
  static const Color primary200 = Color(0xFF08DBA5);
  static const Color primary300 = Color(0xFF05B084);
  static const Color primary400 = Color(0xFF038764);
  static const Color primary500 = Color(0xFF015F46);
  static const Color primary600 = Color(0xFF003B2A);
  static const Color primary700 = Color(0xFF001910);

  static const Color gray100 = Color(0xFFE6EBE9);
  static const Color gray200 = Color(0xFFBDC3C0);
  static const Color gray300 = Color(0xFF979C9A);
  static const Color gray400 = Color(0xFF737775);
  static const Color gray500 = Color(0xFF515453);
  static const Color gray600 = Color(0xFF313332);
  static const Color gray700 = Color(0xFF141515);

  static const Color background = gray100;
  static const Color surface = Colors.white;

  static const Color textPrimary = gray700;
  static const Color textSecondary = gray500;
  static const Color textDisabled = gray400;

  static const Color success = primary400;
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = primary200;

  static const Color border = gray200;
}
