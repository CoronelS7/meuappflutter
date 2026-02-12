import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // 👤 FOTO + INFO
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: const AssetImage(
                      'assets/imagens/pessoa_perfil.png',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "João Silva",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "josedasilva@gmail.com",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 80),

              const Text(
                "Preferências",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      'assets/icones/conta.svg',
                      'Dados da conta',
                      onTap: () {
                        Navigator.of(context).pushNamed('/dados');
                      },
                    ),
                    _divider(),
                    _menuItem(
                      'assets/icones/pagamento.svg',
                      'Pagamentos',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/pagamentos'),
                    ),
                    _divider(),
                    _menuItem(
                      'assets/icones/endereco.svg',
                      'Endereços',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/enderecos'),
                    ),
                    _divider(),
                    _menuItem(
                      'assets/icones/notificacao.svg',
                      'Notificações',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/notificacoes'),
                    ),
                    _divider(),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Outras opções",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      'assets/icones/config.svg',
                      'Configurações',
                      onTap: () => Navigator.of(context).pushNamed('/config'),
                    ),
                    _divider(),
                    _menuItem(
                      'assets/icones/ajuda.svg',
                      'Ajuda e Suporte',
                      onTap: () => Navigator.of(context).pushNamed('/ajuda'),
                    ),
                    _divider(),
                    _menuItem(
                      'assets/icones/sair.svg',
                      'Sair',
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      chevronColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 ITEM CUSTOMIZÁVEL (AGORA COM onTap)
  Widget _menuItem(
    String icon,
    String title, {
    VoidCallback? onTap,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
    Color chevronColor = Colors.black54,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        icon,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: chevronColor),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Divider(height: 1);
  }
}
