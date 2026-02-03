import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

import 'home.dart';
import 'cardapio.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [HomeScreen(), CardapioScreen()];

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex, // 🔴 IMPORTANTE
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      selectedItemColor: AppColors.primary600,
      unselectedItemColor: AppColors.gray400,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/porta.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              _currentIndex == 0 ? AppColors.primary600 : AppColors.gray400,
              BlendMode.srcIn,
            ),
          ),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/cardapio.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              _currentIndex == 1 ? AppColors.primary600 : AppColors.gray400,
              BlendMode.srcIn,
            ),
          ),
          label: 'Cardápio',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/store.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              _currentIndex == 2 ? AppColors.primary600 : AppColors.gray400,
              BlendMode.srcIn,
            ),
          ),
          label: 'Carrinho',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/profile.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              _currentIndex == 3 ? AppColors.primary600 : AppColors.gray400,
              BlendMode.srcIn,
            ),
          ),
          label: 'Perfil',
        ),
      ],
    );
  }
  // ================= BOTTOM NAV =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
