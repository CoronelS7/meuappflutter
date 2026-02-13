import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

class DadosContaScreen extends StatelessWidget {
  const DadosContaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        // 🔹 SETA SVG PERSONALIZADA
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg', // seu svg aqui
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),

        // 🔹 TÍTULO CENTRALIZADO
        centerTitle: true,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ✅ FOTO (NÍVEL 3) + BOTÃO EDITAR
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray300, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 70,
                      backgroundImage: AssetImage(
                        'assets/imagens/pessoa_perfil.png',
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: editar foto
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/icones/edit.svg', // seu svg aqui
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ✅ LISTA (igual print)
            _infoTile(label: 'Nome', value: 'Jose Silva', onTap: () {}),
            const SizedBox(height: 12),

            _infoTile(
              label: 'Email',
              value: 'josedasilva@gmail.com',
              onTap: () {},
            ),
            const SizedBox(height: 12),

            _infoTile(
              label: 'Telefone',
              value: '(11) 99090-9090',
              onTap: () {},
            ),
            const SizedBox(height: 12),

            _infoTile(label: 'CPF', value: '928.123.432-12', onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // label (esquerda)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              // value (direita)
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 10),

              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
