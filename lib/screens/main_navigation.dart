import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';
import 'package:meu_app_flutter/data/pedido_status_data.dart';
import 'package:meu_app_flutter/screens/login.dart';
import 'package:meu_app_flutter/screens/pedido_status_screen.dart';

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
  bool _verificandoCadastroComplementar = false;

  // ✅ Agora PERFIL também é aba
  late final List<Widget> _screens = [
    const HomeScreen(),
    const CardapioScreen(),
    PerfilTab(navigatorKey: _perfilNavKey),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _garantirCadastroComplementarAoAbrir();
    });
  }

  String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  Future<Map<String, dynamic>?> _buscarDadosUsuario(User user) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);

    try {
      final snapshot = await docRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (!snapshot.exists) {
        return <String, dynamic>{};
      }
      return snapshot.data();
    } on FirebaseException {
      try {
        final snapshot = await docRef.get(
          const GetOptions(source: Source.cache),
        );
        if (!snapshot.exists) {
          return <String, dynamic>{};
        }
        return snapshot.data();
      } on FirebaseException {
        return null;
      }
    }
  }

  bool _cadastroComplementarCompleto(User user, Map<String, dynamic>? dados) {
    if (dados == null) {
      return true;
    }

    final nome = (dados['nome'] ?? user.displayName ?? '').toString().trim();
    final telefone = (dados['telefone'] ?? '').toString().trim();
    final cpf = _somenteNumeros((dados['cpf'] ?? '').toString());

    return nome.isNotEmpty && telefone.isNotEmpty && cpf.length == 11;
  }

  Future<void> _garantirCadastroComplementarAoAbrir() async {
    if (_verificandoCadastroComplementar || !mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    _verificandoCadastroComplementar = true;
    try {
      final dados = await _buscarDadosUsuario(user);
      final cadastroCompleto = _cadastroComplementarCompleto(user, dados);
      if (!cadastroCompleto && mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } finally {
      _verificandoCadastroComplementar = false;
    }
  }

  void _openCarrinho() async {
    final shouldGoHome = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = shouldGoHome == true ? 0 : _currentIndex;
    });
  }

  void _abrirStatusPedido() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PedidoStatusScreen()),
    );
  }

  Widget _buildPedidoStatusShortcut() {
    return ValueListenableBuilder<int>(
      valueListenable: PedidoStatusData.shortcutListenable,
      builder: (context, version, child) {
        if (!PedidoStatusData.temPedidoAtivo) {
          return const SizedBox.shrink();
        }

        final mediaQuery = MediaQuery.of(context);
        if (mediaQuery.viewInsets.bottom > 0) {
          return const SizedBox.shrink();
        }

        final etapaAtualIndex = PedidoStatusData.indiceEtapaAtual();
        final etapaTexto =
            '${etapaAtualIndex + 1}/${PedidoStatusData.totalEtapas}';
        final concluido = PedidoStatusData.pedidoConcluido;
        final screenHeight = mediaQuery.size.height;
        final top = (screenHeight * 0.46).clamp(120.0, screenHeight - 220.0);

        return Positioned(
          right: 12,
          top: top.toDouble(),
          child: RepaintBoundary(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _abrirStatusPedido,
                customBorder: const CircleBorder(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF2FFFA)],
                        ),
                        border: Border.all(color: AppColors.gray200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.primary200.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary400,
                                  AppColors.primary300,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary300.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icones/gps_device.svg',
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: concluido
                                    ? AppColors.success
                                    : const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.gray200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        concluido ? 'OK' : 'GPS $etapaTexto',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: concluido
                              ? AppColors.success
                              : AppColors.primary600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex == 2
          ? 2
          : _currentIndex, // (não precisa, mas ok)
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
          setState(
            () => _currentIndex = 2,
          ); // 👈 2 pq Perfil é a 3ª tela da lista
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
            builder: (context, badgeCount, _) {
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
                  if (badgeCount > 0)
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
                            '$badgeCount',
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
    final perfilCanPop =
        _currentIndex == 2 &&
        _perfilNavKey.currentState != null &&
        _perfilNavKey.currentState!.canPop();

    return PopScope(
      canPop: _currentIndex == 0 && !perfilCanPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_currentIndex == 2 &&
            _perfilNavKey.currentState != null &&
            _perfilNavKey.currentState!.canPop()) {
          _perfilNavKey.currentState!.pop();
          return;
        }

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        Navigator.of(context).maybePop();
      },
      child: Scaffold(
        body: Stack(
          children: [_screens[_currentIndex], _buildPedidoStatusShortcut()],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }
}
