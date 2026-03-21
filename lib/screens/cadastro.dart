import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/stripe/stripe_config.dart';
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
  final _cpfCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();

  bool _carregando = false;

  bool _verSenha = false;
  bool _verConfirmarSenha = false;

  double _forcaSenha = 0;
  bool _mostrarBarraSenha = false;
  String _textoForcaSenha = "";

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
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

  double _calcularForcaSenha(String senha) {
    double forca = 0;

    if (senha.length >= 6) forca += 0.25;
    if (senha.length >= 8) forca += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(senha)) forca += 0.25;
    if (RegExp(r'[0-9]').hasMatch(senha)) forca += 0.25;

    if (forca <= 0.25) {
      _textoForcaSenha = "Senha fraca";
    } else if (forca <= 0.50) {
      _textoForcaSenha = "Senha media";
    } else {
      _textoForcaSenha = "Senha forte";
    }

    return forca;
  }

  bool _senhaForte(String senha) {
    return senha.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(senha) &&
        RegExp(r'[0-9]').hasMatch(senha);
  }

  Color _corForcaSenha() {
    if (_forcaSenha <= 0.25) return Colors.red;
    if (_forcaSenha <= 0.50) return Colors.orange;
    if (_forcaSenha <= 0.75) return Colors.yellow;
    return Colors.green;
  }

  Future<_EmailValidationResult> _validarEmailZeroBounce(String email) async {
    try {
      final resposta = await http
          .post(
            Uri.parse('${StripeConfig.backendBaseUrl}/validate-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 8));

      if (resposta.statusCode == 200) {
        final data = jsonDecode(resposta.body);
        if (data is Map<String, dynamic>) {
          return _EmailValidationResult(
            serviceAvailable: true,
            isValid: data['isValid'] == true,
            didYouMean: data['didYouMean'] as String?,
          );
        }
      }

      return const _EmailValidationResult(
        serviceAvailable: false,
        isValid: false,
      );
    } on TimeoutException {
      return const _EmailValidationResult(
        serviceAvailable: false,
        isValid: false,
      );
    } catch (_) {
      return const _EmailValidationResult(
        serviceAvailable: false,
        isValid: false,
      );
    }
  }

  Future<void> _cadastrarUsuario() async {
    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final telefone = _telefoneCtrl.text.trim();
    final cpf = _somenteNumeros(_cpfCtrl.text.trim());
    final senha = _senhaCtrl.text.trim();
    final confirmarSenha = _confirmarSenhaCtrl.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        telefone.isEmpty ||
        cpf.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarMensagem("Preencha todos os campos.", Colors.red);
      return;
    }

    if (cpf.length != 11) {
      _mostrarMensagem("CPF invalido. Digite 11 numeros.", Colors.red);
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarMensagem("As senhas nao coincidem.", Colors.red);
      return;
    }

    if (!_senhaForte(senha)) {
      _mostrarMensagem(
        "Senha fraca. Use 8 caracteres, numero e letra maiuscula.",
        Colors.orange,
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final emailValidation = await _validarEmailZeroBounce(email);
      if (!emailValidation.serviceAvailable) {
        _mostrarMensagem(
          "Nao foi possivel validar o e-mail agora. Tente novamente em instantes.",
          Colors.red,
        );
        return;
      }

      if (!emailValidation.isValid) {
        final suggestion = (emailValidation.didYouMean ?? '').trim();
        if (suggestion.isNotEmpty) {
          _mostrarMensagem(
            "Este e-mail parece invalido. Voce quis dizer $suggestion?",
            Colors.red,
          );
        } else {
          _mostrarMensagem("Este e-mail nao existe.", Colors.red);
        }
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final user = cred.user;
      if (user == null) {
        _mostrarMensagem("Erro ao criar usuario.", Colors.red);
        return;
      }

      await user.updateDisplayName(nome);

      await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .set({
            "uid": user.uid,
            "nome": nome,
            "email": email,
            "telefone": telefone,
            "cpf": cpf,
            "criado_em": FieldValue.serverTimestamp(),
          });

      _mostrarMensagem("Cadastro realizado com sucesso!", Colors.green);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _mostrarMensagem("Este e-mail ja esta cadastrado.", Colors.red);
      } else if (e.code == 'invalid-email') {
        _mostrarMensagem("E-mail invalido.", Colors.red);
      } else if (e.code == 'weak-password') {
        _mostrarMensagem("Senha muito fraca.", Colors.red);
      } else {
        _mostrarMensagem("Erro ao criar usuario.", Colors.red);
      }
    } on FirebaseException {
      _mostrarMensagem("Erro ao salvar dados do usuario.", Colors.red);
    } catch (_) {
      _mostrarMensagem("Erro inesperado ao cadastrar.", Colors.red);
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
        child: Stack(
          children: [
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

                      _buildLabel("Nome"),
                      _buildInput(
                        controller: _nomeCtrl,
                        hint: "Nome",
                        asset: "assets/icones/perfil.svg",
                      ),

                      const SizedBox(height: 15),

                      _buildLabel("Email"),
                      _buildInput(
                        controller: _emailCtrl,
                        hint: "Digite seu email",
                        asset: "assets/icones/email.svg",
                      ),

                      const SizedBox(height: 15),

                      _buildLabel("Telefone"),
                      _buildInput(
                        controller: _telefoneCtrl,
                        hint: "Digite seu telefone",
                        asset: "assets/icones/phone.svg",
                      ),

                      const SizedBox(height: 15),

                      _buildLabel("CPF"),
                      _buildInput(
                        controller: _cpfCtrl,
                        hint: "Digite seu CPF",
                        asset: "assets/icones/conta.svg",
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),

                      const SizedBox(height: 15),

                      _buildLabel("Senha"),
                      _buildInput(
                        controller: _senhaCtrl,
                        hint: "Digite sua senha",
                        asset: "assets/icones/password.svg",
                        obscure: !_verSenha,
                        onChanged: (valor) {
                          if (valor.isNotEmpty) {
                            setState(() {
                              _mostrarBarraSenha = true;
                              _forcaSenha = _calcularForcaSenha(valor);
                            });
                          } else {
                            setState(() {
                              _mostrarBarraSenha = false;
                            });
                          }
                        },
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

                      const SizedBox(height: 10),

                      if (_mostrarBarraSenha)
                        Column(
                          children: [
                            LinearProgressIndicator(
                              value: _forcaSenha,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(
                                _corForcaSenha(),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _textoForcaSenha,
                                style: TextStyle(
                                  color: _corForcaSenha(),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 15),

                      _buildLabel("Confirmar Senha"),
                      _buildInput(
                        controller: _confirmarSenhaCtrl,
                        hint: "Confirmar senha",
                        asset: "assets/icones/password.svg",
                        obscure: !_verConfirmarSenha,
                        suffix: IconButton(
                          icon: Icon(
                            _verConfirmarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _verConfirmarSenha = !_verConfirmarSenha;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 40),

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
                          onPressed: _carregando ? null : _cadastrarUsuario,
                          child: _carregando
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Cadastrar",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
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
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required String asset,
    bool obscure = false,
    Widget? suffix,
    Function(String)? onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: "Poppins", color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class _EmailValidationResult {
  const _EmailValidationResult({
    required this.serviceAvailable,
    required this.isValid,
    this.didYouMean,
  });

  final bool serviceAvailable;
  final bool isValid;
  final String? didYouMean;
}
