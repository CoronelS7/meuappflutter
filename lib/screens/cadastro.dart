import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'main_navigation.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _confirmarsenhaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _confirmarsenhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary400, AppColors.primary200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ================= CONTEÚDO PRINCIPAL =================
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      Image.asset(
                        'assets/imagens/logo.png',
                        height: 204,
                        width: 204,
                      ),

                      const SizedBox(height: 20),

                      // ================= NOME =================
                      _buildLabel("Nome"),
                      _buildInput(
                        controller: _nomeCtrl,
                        hint: 'Nome',
                        asset: 'assets/icones/perfil.svg',
                      ),

                      const SizedBox(height: 15),

                      // ================= EMAIL =================
                      _buildLabel("Email"),
                      _buildInput(
                        controller: _emailCtrl,
                        hint: 'Digite seu email',
                        asset: 'assets/icones/email.svg',
                      ),

                      const SizedBox(height: 15),

                      // ================= TELEFONE =================
                      _buildLabel("Telefone"),
                      _buildInput(
                        controller: _telefoneCtrl,
                        hint: 'Digite seu número',
                        asset: 'assets/icones/phone.svg',
                      ),

                      const SizedBox(height: 15),

                      // ================= SENHA =================
                      _buildLabel("Senha"),
                      _buildInput(
                        controller: _senhaCtrl,
                        hint: 'Digite sua senha',
                        asset: 'assets/icones/password.svg',
                        obscure: true,
                      ),

                      const SizedBox(height: 15),

                      // ================= CONFIRMAR SENHA =================
                      _buildLabel("Confirmar senha"),
                      _buildInput(
                        controller: _confirmarsenhaCtrl,
                        hint: 'Confirmar senha',
                        asset: 'assets/icones/password.svg',
                        obscure: true,
                      ),

                      const SizedBox(height: 40),

                      // ================= BOTÃO =================
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigation(),
                              ),
                            );
                          },
                          child: const Text(
                            'Cadastrar',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // ================= SETA VOLTAR FIXA NO CANTO =================
            Positioned(
              top: 10,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LABEL =================
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================= INPUT COM SVG =================
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required String asset,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
          ),
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
