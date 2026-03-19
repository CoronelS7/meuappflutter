import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/screens/cadastro.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _carregando = false;
  bool _verSenha = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _normalizarCodigoErro(Object erro) {
    if (erro is FirebaseAuthException) return erro.code.toLowerCase();
    if (erro is PlatformException) return erro.code.toLowerCase();
    return erro.toString().toLowerCase();
  }

  void _tratarErroLogin(Object erro) {
    final code = _normalizarCodigoErro(erro);
    final texto = erro.toString().toLowerCase();

    if (code.contains('invalid-email')) {
      _mostrarMensagem('Email invalido.', Colors.red);
      return;
    }

    if (code.contains('invalid-credential') ||
        code.contains('wrong-password') ||
        code.contains('user-not-found') ||
        code.contains('error_invalid_credential') ||
        code.contains('error_wrong_password') ||
        code.contains('error_user_not_found') ||
        texto.contains('invalid_credential')) {
      _mostrarMensagem('Email ou senha invalidos.', Colors.red);
      return;
    }

    if (code.contains('network-request-failed') ||
        code.contains('error_network_request_failed')) {
      _mostrarMensagem('Sem conexao com a internet.', Colors.red);
      return;
    }

    if (code.contains('too-many-requests')) {
      _mostrarMensagem('Muitas tentativas. Tente novamente mais tarde.', Colors.red);
      return;
    }

    _mostrarMensagem('Erro ao fazer login.', Colors.red);
  }

  Future<void> _garantirDocumentoUsuario(User user) async {
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      return;
    }

    await docRef.set({
      'uid': user.uid,
      'nome': user.displayName ?? '',
      'email': user.email ?? '',
      'telefone': '',
      'cpf': '',
      'criado_em': FieldValue.serverTimestamp(),
      'atualizado_em': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loginUsuario() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final senha = _senhaCtrl.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Preencha email e senha.', Colors.red);
      return;
    }

    if (!email.contains('@')) {
      _mostrarMensagem('Digite um email valido.', Colors.red);
      return;
    }

    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      final user = cred.user;
      if (user != null) {
        try {
          await _garantirDocumentoUsuario(user);
        } on FirebaseException {
          // Login ja foi concluido; se o Firestore falhar, a UI usa fallback.
        }
      }

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (erro) {
      if (!mounted) return;
      _tratarErroLogin(erro);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Image.asset(
                      'assets/imagens/logo.png',
                      height: 204,
                      width: 204,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInput(
                    controller: _emailCtrl,
                    hint: 'Digite seu email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Senha',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInput(
                    controller: _senhaCtrl,
                    hint: 'Digite sua senha',
                    icon: Icons.lock_outline,
                    obscure: !_verSenha,
                    suffix: IconButton(
                      icon: Icon(
                        _verSenha ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _verSenha = !_verSenha;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nao tem conta? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CadastroScreen()),
                          );
                        },
                        child: const Text(
                          'Crie uma aqui!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF072684),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
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
                      onPressed: _carregando
                          ? null
                          : () async {
                              try {
                                await _loginUsuario();
                              } catch (erro) {
                                if (mounted) _tratarErroLogin(erro);
                              }
                            },
                      child: _carregando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Acessar',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        inputFormatters: keyboardType == TextInputType.emailAddress
            ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
