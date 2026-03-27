import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';
import 'package:meu_app_flutter/models/product.dart';
import 'package:meu_app_flutter/screens/carrinho.dart';
import 'package:meu_app_flutter/widgets/product_image.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final Map<int, int> _additionalQuantities = <int, int>{};
  final TextEditingController _commentController = TextEditingController();

  List<CartAdditionalSelection> get _selectedAdditionals {
    final orderedIndexes = _additionalQuantities.keys.toList()..sort();

    return orderedIndexes
        .map(
          (index) => CartAdditionalSelection(
            additional: widget.product.additionals[index],
            quantity: _additionalQuantities[index] ?? 0,
          ),
        )
        .where((item) => item.quantity > 0)
        .toList(growable: false);
  }

  double get _totalPrice {
    final additionalsTotal = _selectedAdditionals.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return Product.parsePrice(widget.product.price) + additionalsTotal;
  }

  String get _totalPriceText => Product.formatPrice(_totalPrice);

  void _changeAdditionalQuantity(int index, int delta) {
    final current = _additionalQuantities[index] ?? 0;
    final next = current + delta;

    setState(() {
      if (next <= 0) {
        _additionalQuantities.remove(index);
      } else {
        _additionalQuantities[index] = next;
      }
    });
  }

  void _addToCart() {
    CartData.addProduct(
      widget.product,
      selectedAdditionals: _selectedAdditionals,
      comment: _commentController.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasAdditionals = product.additionals.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary300,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 28,
            height: 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(
              image: product.image,
              width: double.infinity,
              height: screenHeight * 0.4,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Comentario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Adicione uma observacao para o preparo, se quiser.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    minLines: 3,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ex.: sem cebola, carne ao ponto, molho separado...',
                      hintStyle: const TextStyle(
                        color: AppColors.gray400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE9E9E9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary300,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (hasAdditionals) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Adicionais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Escolha quantas unidades de cada adicional deseja incluir.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(product.additionals.length, (index) {
                      final additional = product.additionals[index];
                      final selectedQuantity = _additionalQuantities[index] ?? 0;
                      final isSelected = selectedQuantity > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF5FBF8)
                              : const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary300
                                : const Color(0xFFE9E9E9),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    additional.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+ ${additional.price} cada',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _QuantityButton(
                              icon: Icons.remove,
                              onTap: selectedQuantity == 0
                                  ? null
                                  : () => _changeAdditionalQuantity(index, -1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '$selectedQuantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            _QuantityButton(
                              icon: Icons.add,
                              onTap: () => _changeAdditionalQuantity(index, 1),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icones/store.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Adicionar ao carrinho - $_totalPriceText',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.gray300 : AppColors.primary300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
