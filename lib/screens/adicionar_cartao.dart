import 'package:flutter/material.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _numeroCtrl.dispose();
    _validadeCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primary300,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Adicionar Cartão',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(controller: _nomeCtrl, label: 'Nome no cartão'),
              const SizedBox(height: 12),
              _field(
                controller: _numeroCtrl,
                label: 'Número do cartão',
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _validadeCtrl,
                      label: 'Validade (MM/AA)',
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: _cvvCtrl,
                      label: 'CVV',
                      keyboard: TextInputType.number,
                      obscure: true,
                    ),
                  ),
                ],
              ),
              const Spacer(),

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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        CartaoModel(
                          nome: _nomeCtrl.text,
                          numero: _numeroCtrl.text,
                          validade: _validadeCtrl.text,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Salvar cartão',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INPUT PADRÃO =================
  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
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
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary300, width: 1.5),
        ),
      ),
    );
  }
}
