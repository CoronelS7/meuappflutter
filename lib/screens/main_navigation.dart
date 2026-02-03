import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

import 'home.dart';
import 'cardapio.dart';
import 'carrinho.dart';
import 'perfil.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // ✅ Só as telas que fazem parte da navbar (abas)
  final List<Widget> _screens = const [HomeScreen(), CardapioScreen()];

  void _openCarrinho() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
    );
  }

  void _openPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilScreen()),
    );
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        // ✅ index 0 e 1 são abas
        if (index == 0 || index == 1) {
          setState(() => _currentIndex = index);
          return;
        }

        // ✅ Carrinho abre outra tela (sem navbar)
        if (index == 2) {
          _openCarrinho();
          return;
        }

        // ✅ Perfil também abre outra tela (até você criar a aba)
        if (index == 3) {
          _openPerfil();
          return;
        }
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
              AppColors.gray400, // como não é aba, fica "unselected"
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
              AppColors.gray400, // como não é aba, fica "unselected"
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
