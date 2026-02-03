import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';

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
  final List<Widget> _screens = const [
    HomeScreen(),
    CardapioScreen(),
  ];

  void _openCarrinho() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
    );

    // 🔁 ainda é útil para atualizar a aba atual, mas o badge já atualiza sozinho
    setState(() {});
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

        // ✅ Perfil abre fora da navbar
        if (index == 3) {
          _openPerfil();
          return;
        }
      },
      selectedItemColor: AppColors.primary600,
      unselectedItemColor: AppColors.gray400,
      type: BottomNavigationBarType.fixed,
      items: [
        // ================= INÍCIO =================
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

        // ================= CARDÁPIO =================
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

        // ================= CARRINHO (BADGE REATIVO) =================
        BottomNavigationBarItem(
          icon: ValueListenableBuilder<int>(
            valueListenable: CartData.badgeCount,
            builder: (context, count, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/icones/store.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gray400,
                      BlendMode.srcIn,
                    ),
                  ),

                  // 🔴 BADGE
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Carrinho',
        ),

        // ================= PERFIL =================
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/profile.svg',
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(
              AppColors.gray400,
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
