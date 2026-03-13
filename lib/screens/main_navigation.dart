import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';

import 'home.dart';
import 'cardapio.dart';
import 'carrinho.dart';
import 'perfil_tab.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _perfilNavKey = GlobalKey<NavigatorState>();

  // ✅ Agora PERFIL também é aba
  late final List<Widget> _screens = [
    const HomeScreen(),
    const CardapioScreen(),
    PerfilTab(navigatorKey: _perfilNavKey),
  ];

  void _openCarrinho() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
    );

    // atualiza badge/estado quando voltar
    setState(() {});
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex == 2 ? 2 : _currentIndex, // (não precisa, mas ok)
      onTap: (index) {
        // ✅ Home
        if (index == 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // ✅ Cardápio
        if (index == 1) {
          setState(() => _currentIndex = 1);
          return;
        }

        // ✅ Carrinho abre outra tela (sem navbar)
        if (index == 2) {
          _openCarrinho();
          return;
        }

        // ✅ Perfil agora é ABA (sem push)
        if (index == 3) {
          setState(() => _currentIndex = 2); // 👈 2 pq Perfil é a 3ª tela da lista
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

        // ================= CARRINHO (BADGE) =================
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
            colorFilter: ColorFilter.mode(
              _currentIndex == 2 ? AppColors.primary600 : AppColors.gray400,
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
    return WillPopScope(
      onWillPop: () async {
        // Se estiver na aba de perfil e a pilha interna puder fazer pop, faça isso primeiro
        if (_currentIndex == 2 &&
            _perfilNavKey.currentState != null &&
            _perfilNavKey.currentState!.canPop()) {
          _perfilNavKey.currentState!.pop();
          return false; // não fechar app
        }

        // Se não estiver na aba inicial, volte para ela em vez de fechar o app
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }

        // Senão permite fechar o app
        return true;
      },
      child: Scaffold(
        // ✅ Agora body troca entre 3 abas (0,1,2)
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
}
