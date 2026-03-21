import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  bool _carregando = false;
  bool _verSenha = false;
  bool _resolvendoSessaoExistente = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolverSessaoExistente();
    });
  }

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

  String _somenteNumeros(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  void _tratarErroLogin(Object erro) {
    final code = _normalizarCodigoErro(erro);
    final texto = erro.toString().toLowerCase();
    debugPrint('Erro login: $erro');

    if (code.contains('sign_in_canceled') ||
        code.contains('canceled') ||
        texto.contains('cancel')) {
      _mostrarMensagem('Login com Google cancelado.', Colors.orange);
      return;
    }

    if (code.contains('google_sign_in_failed') ||
        code.contains('sign_in_failed') ||
        code.contains('developer_error') ||
        texto.contains('apiexception: 10') ||
        texto.contains('developer error')) {
      _mostrarMensagem(
        'Google Login nao configurado no Firebase (SHA-1/SHA-256).',
        Colors.red,
      );
      return;
    }

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
        code.contains('error_network_request_failed') ||
        code.contains('network_error')) {
      _mostrarMensagem('Sem conexao com a internet.', Colors.red);
      return;
    }

    if (code.contains('too-many-requests')) {
      _mostrarMensagem(
        'Muitas tentativas. Tente novamente mais tarde.',
        Colors.red,
      );
      return;
    }

    _mostrarMensagem('Erro ao fazer login.', Colors.red);
  }

  Future<void> _resolverSessaoExistente() async {
    if (_resolvendoSessaoExistente || !mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    _resolvendoSessaoExistente = true;
    try {
      await _finalizarLogin(user, exigirCadastroComplementar: true);
    } finally {
      _resolvendoSessaoExistente = false;
    }
  }

  Future<void> _limparSessaoGoogleAnterior() async {
    try {
      final estavaLogadoNoGoogle = await _googleSignIn.isSignedIn();
      if (estavaLogadoNoGoogle) {
        await _googleSignIn.disconnect();
        return;
      }
    } catch (_) {
      // Segue para signOut como fallback.
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignora; o fluxo de signIn trata erros na sequencia.
    }
  }

  Future<void> _garantirDocumentoUsuario(User user) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);
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
      await _finalizarLogin(cred.user);
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

  Future<void> _loginComGoogle() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      await _limparSessaoGoogleAnterior();
      final contaGoogle = await _googleSignIn.signIn();
      if (contaGoogle == null) {
        if (mounted) {
          _mostrarMensagem('Login com Google cancelado.', Colors.orange);
        }
        return;
      }

      final authGoogle = await contaGoogle.authentication;
      if (authGoogle.accessToken == null && authGoogle.idToken == null) {
        throw PlatformException(code: 'google_sign_in_failed');
      }

      final credencial = GoogleAuthProvider.credential(
        accessToken: authGoogle.accessToken,
        idToken: authGoogle.idToken,
      );

      final resultado = await FirebaseAuth.instance.signInWithCredential(
        credencial,
      );
      final isNovoUsuarioGoogle =
          resultado.additionalUserInfo?.isNewUser ?? false;

      await _finalizarLogin(
        resultado.user,
        exigirCadastroComplementar: true,
        abrirCadastroDireto: isNovoUsuarioGoogle,
      );
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

  Future<void> _finalizarLogin(
    User? user, {
    bool exigirCadastroComplementar = false,
    bool abrirCadastroDireto = false,
  }) async {
    if (user != null) {
      if (exigirCadastroComplementar) {
        final cadastroCompleto = await _garantirCadastroComplementar(
          user,
          assumirIncompleto: abrirCadastroDireto,
        );
        if (!cadastroCompleto) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      } else {
        try {
          await _garantirDocumentoUsuario(user);
        } on FirebaseException {
          // Login ja foi concluido; se o Firestore falhar, a UI usa fallback.
        }
      }
    }

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      await Navigator.of(context).maybePop(true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  Future<bool> _garantirCadastroComplementar(
    User user, {
    bool assumirIncompleto = false,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);
    Map<String, dynamic> dados = <String, dynamic>{};
    dynamic criadoEmAtual;

    if (!assumirIncompleto) {
      DocumentSnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await docRef.get(
          const GetOptions(source: Source.serverAndCache),
        );
      } on FirebaseException {
        snapshot = await docRef.get(const GetOptions(source: Source.cache));
      }
      dados = snapshot.data() ?? <String, dynamic>{};
      criadoEmAtual = dados['criado_em'];
    }

    final nomeAtual = (dados['nome'] ?? user.displayName ?? '')
        .toString()
        .trim();
    final telefoneAtual = (dados['telefone'] ?? '').toString().trim();
    final cpfAtual = _somenteNumeros((dados['cpf'] ?? '').toString());

    final precisaComplementar = assumirIncompleto
        ? true
        : nomeAtual.isEmpty || telefoneAtual.isEmpty || cpfAtual.length != 11;

    if (!precisaComplementar) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    final nomeCtrl = TextEditingController(text: nomeAtual);
    final telefoneCtrl = TextEditingController(text: telefoneAtual);
    final cpfCtrl = TextEditingController(text: cpfAtual);
    final formKey = GlobalKey<FormState>();
    var salvando = false;

    final concluiu = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> salvar() async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setModalState(() {
                salvando = true;
              });

              try {
                final nome = nomeCtrl.text.trim();
                final telefone = _somenteNumeros(telefoneCtrl.text.trim());
                final cpf = _somenteNumeros(cpfCtrl.text.trim());

                await docRef.set({
                  'uid': user.uid,
                  'nome': nome,
                  'email': user.email ?? '',
                  'telefone': telefone,
                  'cpf': cpf,
                  'criado_em': criadoEmAtual ?? FieldValue.serverTimestamp(),
                  'atualizado_em': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if ((user.displayName ?? '').trim() != nome) {
                  await user.updateDisplayName(nome);
                }

                if (!sheetContext.mounted) return;
                FocusManager.instance.primaryFocus?.unfocus();
                await Future<void>.delayed(const Duration(milliseconds: 10));
                if (!sheetContext.mounted) return;
                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop(true);
                }
              } catch (_) {
                if (!sheetContext.mounted) return;
                _mostrarMensagem(
                  'Nao foi possivel salvar seus dados agora.',
                  Colors.red,
                );
                setModalState(() {
                  salvando = false;
                });
              }
            }

            return PopScope(
              canPop: false,
              child: FractionallySizedBox(
                heightFactor: 0.78,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Form(
                      key: formKey,
                      child: ListView(
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Complete seu cadastro',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Para continuar, informe nome, telefone e CPF.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPerfilInput(
                            controller: nomeCtrl,
                            label: 'Nome completo',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Campo obrigatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildPerfilInput(
                            controller: telefoneCtrl,
                            label: 'Telefone',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              final telefone = _somenteNumeros(value ?? '');
                              if (telefone.length < 10) {
                                return 'Telefone invalido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildPerfilInput(
                            controller: cpfCtrl,
                            label: 'CPF',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              final cpf = _somenteNumeros(value ?? '');
                              if (cpf.length != 11) {
                                return 'CPF invalido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary300,
                              ),
                              onPressed: salvando ? null : salvar,
                              child: salvando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Salvar e continuar',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nomeCtrl.dispose();
    telefoneCtrl.dispose();
    cpfCtrl.dispose();

    if (concluiu != true) {
      _mostrarMensagem('Complete seu cadastro para continuar.', Colors.orange);
    }

    return concluiu == true;
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
                            MaterialPageRoute(
                              builder: (_) => const CadastroScreen(),
                            ),
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
                  const SizedBox(height: 22),
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(color: Colors.white70, thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.white70, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _carregando ? null : _loginComGoogle,
                        borderRadius: BorderRadius.circular(999),
                        child: Opacity(
                          opacity: _carregando ? 0.65 : 1,
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset('assets/icones/goo.png'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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

  Widget _buildPerfilInput({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      scrollPadding: EdgeInsets.zero,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.gray500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary300),
        ),
      ),
    );
  }
}
