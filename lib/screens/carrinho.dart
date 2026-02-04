import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';
import 'package:meu_app_flutter/screens/metodo_pagamento.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  MetodoPagamento? _metodoPagamento;

  // ================= PREÇO =================
  double _parsePrice(String priceText) {
    final cleaned = priceText
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get _total {
    double sum = 0;
    for (final item in CartData.items) {
      sum += _parsePrice(item.product.price) * item.quantity;
    }
    return sum;
  }

  String _formatBRL(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  // ================= AÇÕES =================
  void _clearCart() {
    setState(() {
      CartData.clear();
    });
  }

  void _increaseQty(int index) {
    setState(() {
      CartData.increase(index);
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      CartData.decrease(index);
    });
  }

  String get _metodoPagamentoTexto {
    switch (_metodoPagamento) {
      case MetodoPagamento.googlePay:
        return 'Google Pay';
      case MetodoPagamento.pix:
        return 'PIX';
      default:
        return 'Escolher >';
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isEmpty = CartData.items.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: AppColors.primary300,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isEmpty ? null : _clearCart,
            child: Text(
              'Limpar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isEmpty ? Colors.white.withOpacity(0.6) : Colors.white,
              ),
            ),
          ),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // LISTA DE ITENS
          Expanded(
            child: isEmpty
                ? Center(
                    child: Text(
                      'Seu carrinho está vazio',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: CartData.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = CartData.items[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                item.product.image,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.product.price,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _decreaseQty(index),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _increaseQty(index),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ================= RESUMO =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatBRL(_total),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // MÉTODO PAGAMENTO
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MetodoPagamentoScreen(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _metodoPagamento = result;
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Método Pagamento',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      Text(
                        _metodoPagamentoTexto,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.primary300,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // BOTÃO FINALIZAR
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmpty
                          ? AppColors.gray300
                          : AppColors.primary300,
                    ),
                    onPressed: isEmpty
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checkout em breve 😉'),
                              ),
                            );
                          },
                    child: const Text(
                      'Finalizar Pedido',
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
        ],
      ),
    );
  }
}
