import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

class CartaoModel {
  final String nome;
  final String numero;
  final String validade;

  CartaoModel({
    required this.nome,
    required this.numero,
    required this.validade,
  });
}

class AdicionarCartaoScreen extends StatefulWidget {
  const AdicionarCartaoScreen({super.key});

  @override
  State<AdicionarCartaoScreen> createState() => _AdicionarCartaoScreenState();
}

class _AdicionarCartaoScreenState extends State<AdicionarCartaoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _validadeCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  final _nomeFocus = FocusNode();
  final _numeroFocus = FocusNode();
  final _validadeFocus = FocusNode();
  final _cvvFocus = FocusNode();

  bool _isSaving = false;

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) {
      return 'Informe o nome no cartao';
    }

    if (name.length < 3) {
      return 'Nome muito curto';
    }

    return null;
  }

  String? _validateCardNumber(String? value) {
    final digits = _onlyDigits(value ?? '');
    if (digits.isEmpty) {
      return 'Informe o numero do cartao';
    }

    if (digits.length < 13 || digits.length > 19) {
      return 'Numero de cartao invalido';
    }

    return null;
  }

  String? _validateExpiry(String? value) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return 'Informe a validade';
    }

    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(clean);
    if (match == null) {
      return 'Use o formato MM/AA';
    }

    final month = int.tryParse(match.group(1)!);
    final year = int.tryParse(match.group(2)!);
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Validade invalida';
    }

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year % 100;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Cartao vencido';
    }

    return null;
  }

  String? _validateCvv(String? value) {
    final digits = _onlyDigits(value ?? '');
    if (digits.length < 3 || digits.length > 4) {
      return 'CVV invalido';
    }

    return null;
  }

  void _saveCard() {
    _dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    Navigator.pop(
      context,
      CartaoModel(
        nome: _nomeCtrl.text.trim(),
        numero: _onlyDigits(_numeroCtrl.text),
        validade: _validadeCtrl.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _numeroCtrl.dispose();
    _validadeCtrl.dispose();
    _cvvCtrl.dispose();

    _nomeFocus.dispose();
    _numeroFocus.dispose();
    _validadeFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppColors.primary300,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icones/arrow.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Adicionar cartao',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

              return AnimatedPadding(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - keyboardInset - 24,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(
                            controller: _nomeCtrl,
                            label: 'Nome no cartao',
                            focusNode: _nomeFocus,
                            keyboard: TextInputType.name,
                            validator: _validateName,
                            autofillHints: const [AutofillHints.creditCardName],
                            textCapitalization: TextCapitalization.words,
                            onFieldSubmitted: (_) {
                              _numeroFocus.requestFocus();
                            },
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _numeroCtrl,
                            label: 'Numero do cartao',
                            focusNode: _numeroFocus,
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(19),
                              _CardNumberInputFormatter(),
                            ],
                            validator: _validateCardNumber,
                            autofillHints: const [
                              AutofillHints.creditCardNumber,
                            ],
                            onFieldSubmitted: (_) {
                              _validadeFocus.requestFocus();
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _validadeCtrl,
                                  label: 'Validade (MM/AA)',
                                  focusNode: _validadeFocus,
                                  keyboard: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryDateInputFormatter(),
                                  ],
                                  validator: _validateExpiry,
                                  autofillHints: const [
                                    AutofillHints.creditCardExpirationDate,
                                  ],
                                  onFieldSubmitted: (_) {
                                    _cvvFocus.requestFocus();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  controller: _cvvCtrl,
                                  label: 'CVV',
                                  focusNode: _cvvFocus,
                                  keyboard: TextInputType.number,
                                  obscure: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: _validateCvv,
                                  autofillHints: const [
                                    AutofillHints.creditCardSecurityCode,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    _saveCard();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveCard,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Salvar cartao',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
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
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      obscureText: obscure,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      validator: validator,
      onTapOutside: (_) => _dismissKeyboard(),
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.gray300,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.primary300,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary300, width: 1.5),
        ),
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final truncated = digits.length > 4 ? digits.substring(0, 4) : digits;
    final buffer = StringBuffer();

    for (int i = 0; i < truncated.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(truncated[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
