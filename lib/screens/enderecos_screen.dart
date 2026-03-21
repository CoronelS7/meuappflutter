import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/endereco_usuario_data.dart';

class EnderecosScreen extends StatefulWidget {
  const EnderecosScreen({super.key});

  @override
  State<EnderecosScreen> createState() => _EnderecosScreenState();
}

class _EnderecosScreenState extends State<EnderecosScreen> {
  final Map<String, Map<String, String>> _viaCepCache = {};

  void _mostrarMensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: erro ? Colors.red : AppColors.primary300,
        ),
      );
  }

  String _somenteDigitos(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  String? _validarObrigatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  Future<Map<String, String>?> _buscarCepViaCep(
    String cepSomenteDigitos,
  ) async {
    final cached = _viaCepCache[cepSomenteDigitos];
    if (cached != null) {
      return cached;
    }

    final url = Uri.parse('https://viacep.com.br/ws/$cepSomenteDigitos/json/');
    final response = await http.get(url).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return null;
    }

    if (data['erro'] == true) {
      return null;
    }

    final parsed = <String, String>{
      'logradouro': (data['logradouro'] ?? '').toString(),
      'bairro': (data['bairro'] ?? '').toString(),
      'cidade': (data['localidade'] ?? '').toString(),
      'uf': (data['uf'] ?? '').toString(),
      'cep': (data['cep'] ?? '').toString(),
    };

    _viaCepCache[cepSomenteDigitos] = parsed;
    return parsed;
  }

  Future<void> _abrirFormularioEndereco({EnderecoUsuario? inicial}) async {
    final cepCtrl = TextEditingController(text: inicial?.cep ?? '');
    final ruaCtrl = TextEditingController(text: inicial?.rua ?? '');
    final bairroCtrl = TextEditingController(text: inicial?.bairro ?? '');
    final cidadeCtrl = TextEditingController(text: inicial?.cidade ?? '');
    final estadoCtrl = TextEditingController(text: inicial?.estado ?? '');
    final numeroCtrl = TextEditingController(text: inicial?.numero ?? '');
    final complementoCtrl = TextEditingController(
      text: inicial?.complemento ?? '',
    );
    final formKey = GlobalKey<FormState>();

    var buscandoCep = false;
    String? erroCep;
    String ultimoCepBuscado = _somenteDigitos(cepCtrl.text.trim());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final bottomInset = mediaQuery.viewInsets.bottom;
        final sheetHeight = mediaQuery.size.height - mediaQuery.padding.top - 12;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> onCepChanged(String valor) async {
              final cep = _somenteDigitos(valor);

              if (cep.length != 8) {
                return;
              }

              if (buscandoCep || cep == ultimoCepBuscado) {
                return;
              }

              setModalState(() {
                buscandoCep = true;
                erroCep = null;
              });

              try {
                final data = await _buscarCepViaCep(cep);
                if (data == null) {
                  setModalState(() {
                    erroCep = 'CEP nao encontrado.';
                    ruaCtrl.clear();
                    bairroCtrl.clear();
                    cidadeCtrl.clear();
                    estadoCtrl.clear();
                  });
                  return;
                }

                setModalState(() {
                  ultimoCepBuscado = cep;
                  cepCtrl.text = _somenteDigitos((data['cep'] ?? '').trim());
                  ruaCtrl.text = (data['logradouro'] ?? '').trim();
                  bairroCtrl.text = (data['bairro'] ?? '').trim();
                  cidadeCtrl.text = (data['cidade'] ?? '').trim();
                  estadoCtrl.text = (data['uf'] ?? '').trim();
                });
              } catch (_) {
                setModalState(() {
                  erroCep = 'Nao foi possivel buscar o CEP.';
                  ruaCtrl.clear();
                  bairroCtrl.clear();
                  cidadeCtrl.clear();
                  estadoCtrl.clear();
                });
              } finally {
                setModalState(() {
                  buscandoCep = false;
                });
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: sheetHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Expanded(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary100,
                                    border: Border.all(
                                      color: AppColors.primary200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.flash_on_rounded,
                                        color: AppColors.primary600,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Digite o CEP para preencher automaticamente.',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  inicial == null
                                      ? 'Adicionar endereco'
                                      : 'Editar endereco',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _campoEndereco(
                                  controller: cepCtrl,
                                  label: 'CEP',
                                  validator: (value) {
                                    final digits = _somenteDigitos(value ?? '');
                                    if (digits.isEmpty) return 'Campo obrigatorio';
                                    if (digits.length != 8) return 'CEP invalido';
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  maxLength: 8,
                                  onChanged: onCepChanged,
                                  helperText: erroCep,
                                  suffixIcon: buscandoCep
                                      ? const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : IconButton(
                                          onPressed: () => onCepChanged(
                                            cepCtrl.text,
                                          ),
                                          icon: const Icon(
                                            Icons.search_rounded,
                                            color: AppColors.primary500,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                _campoEndereco(
                                  controller: ruaCtrl,
                                  label: 'Endereco',
                                  validator: _validarObrigatorio,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 10),
                                _campoEndereco(
                                  controller: bairroCtrl,
                                  label: 'Bairro',
                                  validator: _validarObrigatorio,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 10),
                                _campoEndereco(
                                  controller: estadoCtrl,
                                  label: 'UF',
                                  validator: _validarObrigatorio,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 10),
                                _campoEndereco(
                                  controller: cidadeCtrl,
                                  label: 'Cidade',
                                  validator: _validarObrigatorio,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 10),
                                _campoEndereco(
                                  controller: numeroCtrl,
                                  label: 'Numero',
                                  validator: _validarObrigatorio,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 10),
                                _campoEndereco(
                                  controller: complementoCtrl,
                                  label: 'Complemento',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary300,
                            ),
                            onPressed: () async {
                              if (buscandoCep) {
                                _mostrarMensagem(
                                  'Aguarde a consulta do CEP terminar.',
                                  erro: true,
                                );
                                return;
                              }

                              if (!(formKey.currentState?.validate() ?? false)) {
                                return;
                              }

                              final endereco = EnderecoUsuario(
                                id: inicial?.id ?? '',
                                rua: ruaCtrl.text.trim(),
                                numero: numeroCtrl.text.trim(),
                                bairro: bairroCtrl.text.trim(),
                                cidade: cidadeCtrl.text.trim(),
                                estado: estadoCtrl.text.trim().toUpperCase(),
                                cep: _somenteDigitos(cepCtrl.text.trim()),
                                complemento: complementoCtrl.text.trim(),
                                padrao: inicial?.padrao ?? false,
                              );

                              try {
                                if (inicial == null) {
                                  await EnderecoUsuarioData.salvarNovoEndereco(
                                    endereco,
                                  );
                                } else {
                                  await EnderecoUsuarioData.atualizarEndereco(
                                    inicial.id,
                                    endereco,
                                  );
                                }

                                if (!sheetContext.mounted || !mounted) return;
                                Navigator.pop(sheetContext);
                                _mostrarMensagem(
                                  inicial == null
                                      ? 'Endereco adicionado com sucesso.'
                                      : 'Endereco atualizado com sucesso.',
                                );
                              } catch (_) {
                                if (!mounted) return;
                                _mostrarMensagem(
                                  'Nao foi possivel salvar o endereco.',
                                  erro: true,
                                );
                              }
                            },
                            child: Text(
                              inicial == null
                                  ? 'Salvar endereco'
                                  : 'Atualizar endereco',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
          },
        );
      },
    );
  }

  Future<void> _confirmarRemocao(EnderecoUsuario endereco) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover endereco'),
          content: const Text('Deseja remover este endereco salvo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await EnderecoUsuarioData.removerEndereco(endereco.id);
      if (!mounted) return;
      _mostrarMensagem('Endereco removido.');
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Nao foi possivel remover o endereco.', erro: true);
    }
  }

  void _showAddressOptions(EnderecoUsuario endereco) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                _sheetItem(
                  title: 'Editar',
                  onTap: () {
                    Navigator.pop(ctx);
                    _abrirFormularioEndereco(inicial: endereco);
                  },
                ),
                if (!endereco.padrao)
                  _sheetItem(
                    title: 'Definir como padrao',
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await EnderecoUsuarioData.definirComoPadrao(
                          endereco.id,
                        );
                        if (!mounted) return;
                        _mostrarMensagem('Endereco padrao atualizado.');
                      } catch (_) {
                        if (!mounted) return;
                        _mostrarMensagem(
                          'Nao foi possivel definir como padrao.',
                          erro: true,
                        );
                      }
                    },
                  ),
                _sheetItem(
                  title: 'Remover',
                  isDanger: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmarRemocao(endereco);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Enderecos',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Faca login para gerenciar seus enderecos.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            )
          : StreamBuilder<List<EnderecoUsuario>>(
              stream: EnderecoUsuarioData.streamEnderecos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final enderecos = snapshot.data ?? const <EnderecoUsuario>[];

                if (enderecos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: _addEnderecoTile(
                      label: 'Adicionar endereco',
                      onTap: () => _abrirFormularioEndereco(),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: enderecos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final endereco = enderecos[index];
                            return _addressCard(endereco: endereco);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _addEnderecoTile(
                        label: 'Adicionar endereco',
                        onTap: () => _abrirFormularioEndereco(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _addressCard({required EnderecoUsuario endereco}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          if (endereco.padrao) {
            return;
          }

          try {
            await EnderecoUsuarioData.definirComoPadrao(endereco.id);
            if (!mounted) return;
            _mostrarMensagem('Endereco padrao atualizado.');
          } catch (_) {
            if (!mounted) return;
            _mostrarMensagem(
              'Nao foi possivel atualizar endereco padrao.',
              erro: true,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: endereco.padrao
                  ? AppColors.primary300
                  : const Color(0xFFE3E3E3),
              width: endereco.padrao ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icones/location.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.black87,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            endereco.titulo,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (endereco.padrao)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Padrao',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endereco.subtitulo,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endereco.cepFormatado,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showAddressOptions(endereco),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: SvgPicture.asset(
                    'assets/icones/menu_dots.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.black54,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addEnderecoTile({required String label, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray500),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem({
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? Colors.red : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoEndereco({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool readOnly = false,
    TextInputType? keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: readOnly ? AppColors.gray400 : AppColors.gray500,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: helperText == null ? Colors.transparent : Colors.red,
          fontFamily: 'Poppins',
          fontSize: 12,
        ),
        suffixIcon: suffixIcon,
        counterText: '',
        fillColor: readOnly ? AppColors.gray100 : null,
        filled: readOnly,
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
