import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  // Converte "R$ 24,90" -> 24.90
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
    // Formata tipo 12.5 -> "12,50"
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  void _clearCart() {
    setState(() {
      CartData.items.clear();
    });
  }

  void _increaseQty(int index) {
    setState(() {
      CartData.items[index].quantity++;
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (CartData.items[index].quantity > 1) {
        CartData.items[index].quantity--;
      } else {
        CartData.items.removeAt(index);
      }
    });
  }

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
                fontWeight: FontWeight.w400,
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.product.price,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // CONTADOR
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
              crossAxisAlignment: CrossAxisAlignment.start,
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

                // MÉTODO DE PAGAMENTO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Método Pagamento',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      'Escolher >',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: AppColors.gray700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isEmpty
                        ? null
                        : () {
                            // Finalizar pedido (lógica depois)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Checkout em breve 😉"),
                                duration: Duration(milliseconds: 900),
                              ),
                            );
                          },
                    child: const Text(
                      'Finalizar Pedido',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
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
