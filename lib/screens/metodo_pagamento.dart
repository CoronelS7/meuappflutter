import 'package:flutter/material.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/screens/pagamentos_screen.dart';
import 'package:meu_app_flutter/stripe/customer_identity_service.dart';
import 'package:meu_app_flutter/stripe/payment_methods_service.dart';

enum MetodoPagamento { googlePay, pix, cartao }

class MetodoPagamentoSelecao {
  const MetodoPagamentoSelecao({required this.metodo, required this.resumo});

  final MetodoPagamento metodo;
  final String resumo;
}

class MetodoPagamentoScreen extends StatefulWidget {
  const MetodoPagamentoScreen({super.key});

  @override
  State<MetodoPagamentoScreen> createState() => _MetodoPagamentoScreenState();
}

class _MetodoPagamentoScreenState extends State<MetodoPagamentoScreen> {
  final CustomerIdentityService _customerIdentityService =
      CustomerIdentityService();
  final PaymentMethodsService _paymentMethodsService =
      const PaymentMethodsService();

  MetodoPagamento? _metodoSelecionado;
  List<SavedPaymentMethod> _savedCards = const [];
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    setState(() {
      _isLoadingCards = true;
    });

    try {
      final customerKey = await _customerIdentityService
          .getOrCreateCustomerKey();
      final cards = await _paymentMethodsService.listSavedCards(
        customerKey: customerKey,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedCards = cards;
        _isLoadingCards = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _savedCards = const [];
        _isLoadingCards = false;
      });
    }
  }

  Future<void> _openPaymentsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PagamentosScreen()),
    );

    await _loadSavedCards();
    if (!mounted || _savedCards.isEmpty) {
      return;
    }

    setState(() {
      _metodoSelecionado = MetodoPagamento.cartao;
    });
  }

  String get _cartaoResumo {
    if (_isLoadingCards) {
      return 'Carregando cartoes salvos';
    }

    if (_savedCards.isEmpty) {
      return 'Cartao com Stripe PaymentSheet';
    }

    final defaultCard = _savedCards.firstWhere(
      (card) => card.isDefault,
      orElse: () => _savedCards.first,
    );

    return '${_brandLabel(defaultCard.brand)} **** ${defaultCard.last4}';
  }

  String _resumoMetodoSelecionado(MetodoPagamento metodo) {
    switch (metodo) {
      case MetodoPagamento.googlePay:
        return 'Google Pay';
      case MetodoPagamento.pix:
        return 'PIX';
      case MetodoPagamento.cartao:
        return _savedCards.isEmpty ? 'Cartao' : _cartaoResumo;
    }
  }

  String _brandLabel(String brand) {
    final normalized = brand.toLowerCase();
    if (normalized.isEmpty || normalized == 'card') {
      return 'Cartao';
    }

    if (normalized == 'mastercard') {
      return 'Mastercard';
    }

    if (normalized == 'visa') {
      return 'Visa';
    }

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: RadioGroup<MetodoPagamento>(
        groupValue: _metodoSelecionado,
        onChanged: (selected) {
          setState(() {
            _metodoSelecionado = selected;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Metodo de Pagamento',
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
              subtitle: 'Pagamento rapido pelo Google',
              icon: Icons.payment,
              value: MetodoPagamento.googlePay,
            ),
            _paymentOption(
              title: 'PIX',
              subtitle: 'Pagamento instantaneo',
              icon: Icons.qr_code,
              value: MetodoPagamento.pix,
            ),
            _paymentOption(
              title: 'Cartao',
              subtitle: _cartaoResumo,
              icon: Icons.credit_card,
              value: MetodoPagamento.cartao,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openPaymentsScreen,
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
                        'Adicionar cartao',
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
                          final metodo = _metodoSelecionado!;
                          Navigator.pop(
                            context,
                            MetodoPagamentoSelecao(
                              metodo: metodo,
                              resumo: _resumoMetodoSelecionado(metodo),
                            ),
                          );
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
      ),
    );
  }

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
                activeColor: AppColors.primary300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
