import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

import 'perfil.dart';
import 'dados_conta.dart';
import 'pagamentos_screen.dart';
import 'enderecos_screen.dart';
import 'notificacoes_screen.dart';
import 'configuracoes_screen.dart';
import 'ajuda_suporte_screen.dart';
import 'login.dart';
import 'cadastro.dart';

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;

        if (user == null) {
          return const PerfilNaoLogadoScreen();
        }

        return Navigator(
          key: navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            late final Widget page;

            switch (settings.name) {
              case '/':
                page = const PerfilScreen();
                break;
              case '/dados':
                page = const DadosContaScreen();
                break;
              case '/pagamentos':
                page = const PagamentosScreen();
                break;
              case '/enderecos':
                page = const EnderecosScreen();
                break;
              case '/notificacoes':
                page = const NotificacoesScreen();
                break;
              case '/config':
                page = const ConfiguracoesScreen();
                break;
              case '/ajuda':
                page = const AjudaSuporteScreen();
                break;
              default:
                page = const PerfilScreen();
            }

            return MaterialPageRoute(builder: (_) => page, settings: settings);
          },
        );
      },
    );
  }
}

class PerfilNaoLogadoScreen extends StatelessWidget {
  const PerfilNaoLogadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Você ainda não está conectado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Entrar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.gray500, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CadastroScreen()),
                      );
                    },
                    child: const Text(
                      'Criar conta',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
