import 'package:flutter/material.dart';
import 'perfil.dart';
import 'dados_conta.dart';
import 'pagamentos_screen.dart';
import 'enderecos_screen.dart';
import 'notificacoes_screen.dart';
import 'configuracoes_screen.dart';
import 'ajuda_suporte_screen.dart';

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
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
  }
}
