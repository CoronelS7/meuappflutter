import 'package:flutter/material.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/screens/adicionar_cartao.dart';

enum MetodoPagamento { googlePay, pix, cartao }

class MetodoPagamentoScreen extends StatefulWidget {
  const MetodoPagamentoScreen({super.key});

  @override
  State<MetodoPagamentoScreen> createState() => _MetodoPagamentoScreenState();
}

class _MetodoPagamentoScreenState extends State<MetodoPagamentoScreen> {
  MetodoPagamento? _metodoSelecionado;
  CartaoModel? _cartaoSalvo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      // ================= BODY =================
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Método de Pagamento',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _paymentOption(
            title: 'Google Pay',
            subtitle: 'GooglePay',
            icon: Icons.payment,
            value: MetodoPagamento.googlePay,
          ),

          _paymentOption(
            title: 'PIX',
            subtitle: 'Pagamento instantâneo',
            icon: Icons.qr_code,
            value: MetodoPagamento.pix,
          ),

          // ================= CARTÃO =================
          if (_cartaoSalvo != null)
            _paymentOption(
              title: 'Cartão',
              subtitle:
                  '**** ${_cartaoSalvo!.numero.substring(_cartaoSalvo!.numero.length - 4)}',
              icon: Icons.credit_card,
              value: MetodoPagamento.cartao,
            ),

          // ================= ADICIONAR CARTÃO =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final cartao = await Navigator.push<CartaoModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdicionarCartaoScreen(),
                  ),
                );

                if (cartao != null) {
                  setState(() {
                    _cartaoSalvo = cartao;
                    _metodoSelecionado = MetodoPagamento.cartao;
                  });
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray500),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text(
                      'Adicionar cartão',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // ================= BOTÃO SELECIONAR =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _metodoSelecionado == null
                    ? null
                    : () {
                        Navigator.pop(context, _metodoSelecionado);
                      },
                child: const Text(
                  'Selecionar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 38),
        ],
      ),
    );
  }

  // ================= ITEM DE PAGAMENTO =================
  Widget _paymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required MetodoPagamento value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _metodoSelecionado = value;
          });
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _metodoSelecionado == value
                  ? AppColors.primary300
                  : AppColors.gray300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<MetodoPagamento>(
                value: value,
                groupValue: _metodoSelecionado,
                activeColor: AppColors.primary300,
                onChanged: (val) {
                  setState(() {
                    _metodoSelecionado = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
