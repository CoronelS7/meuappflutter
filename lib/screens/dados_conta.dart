import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

class DadosContaScreen extends StatelessWidget {
  const DadosContaScreen({super.key});

  Future<Map<String, dynamic>?> _buscarDados() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Map<String, dynamic>? _dadosFallback() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return {
      'nome': (user.displayName ?? '').trim(),
      'email': (user.email ?? '').trim(),
      'telefone': '',
      'cpf': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),

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

      body: FutureBuilder(
        future: _buscarDados(),
        builder: (context, snapshot) {
          final dados = snapshot.data ?? _dadosFallback();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dados == null) {
            return const Center(
              child: Text("Usuário não encontrado"),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                const SizedBox(height: 30),

                /// FOTO
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gray300,
                            width: 3,
                          ),
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
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.gray200,
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/icones/edit.svg',
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

                /// NOME
                _infoTile(
                  label: 'Nome',
                  value: dados["nome"] ?? "",
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                /// EMAIL
                _infoTile(
                  label: 'Email',
                  value: dados["email"] ?? "",
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                /// TELEFONE
                _infoTile(
                  label: 'Telefone',
                  value: dados["telefone"] ?? "",
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                /// CPF
                _infoTile(
                  label: 'CPF',
                  value: dados["cpf"] ?? "",
                  onTap: () {},
                ),
              ],
            ),
          );
        },
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
