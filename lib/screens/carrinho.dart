import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';
import 'package:meu_app_flutter/data/notificacoes_data.dart';
import 'package:meu_app_flutter/screens/metodo_pagamento.dart';
import 'package:meu_app_flutter/screens/login.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  MetodoPagamento? _metodoPagamento;

  bool _isLogado = false;

  @override
  void initState() {
    super.initState();

    _isLogado = FirebaseAuth.instance.currentUser != null;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _isLogado = user != null;
        });
      }
    });
  }

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

  void _removerItem(int index) {
    setState(() {
      CartData.remove(index);
    });
  }

  void _finalizarPedido() {
    final quantidadeItens = CartData.totalItems;
    final totalPedido = _total;
    final itensPedido = CartData.items
        .map(
          (item) => NotificationOrderItem(
            nome: item.product.name,
            imagem: item.product.image,
            quantidade: item.quantity,
            precoUnitario: _parsePrice(item.product.price),
          ),
        )
        .toList(growable: false);

    NotificacoesData.adicionarPedidoFinalizado(
      quantidadeItens: quantidadeItens,
      total: totalPedido,
      itens: itensPedido,
    );

    setState(() {
      CartData.clear();
      _metodoPagamento = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido finalizado! Veja em Notificacoes.')),
    );
  }

  Future<void> _irParaLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    final isEmpty = CartData.items.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
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
                color: isEmpty
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isEmpty
                ? Center(
                    child: Text(
                      'Seu carrinho esta vazio',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: CartData.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = CartData.items[index];

                      return CartItemWidget(
                        item: item,
                        onDelete: () => _removerItem(index),
                        onIncrease: () => _increaseQty(index),
                        onDecrease: () => _decreaseQty(index),
                      );
                    },
                  ),
          ),
          _buildBottom(isEmpty),
        ],
      ),
    );
  }

  Widget _buildBottom(bool isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                _formatBRL(_total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: !_isLogado
                ? _irParaLogin
                : () async {
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
                const Text('Metodo Pagamento'),
                Text(
                  !_isLogado ? 'Faca login >' : _metodoPagamentoTexto,
                  style: TextStyle(
                    color: !_isLogado ? Colors.red : AppColors.primary300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (!_isLogado || isEmpty)
                    ? AppColors.gray300
                    : AppColors.primary300,
              ),
              onPressed: (!_isLogado || isEmpty)
                  ? _irParaLogin
                  : _finalizarPedido,
              child: const Text(
                'Finalizar Pedido',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ================= ITEM =================

class CartItemWidget extends StatefulWidget {
  final dynamic item;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  double offset = 0;
  final double maxDrag = -80;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      offset += details.delta.dx;
      if (offset < maxDrag) offset = maxDrag;
      if (offset > 0) offset = 0;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      offset = offset < -40 ? maxDrag : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Stack(
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(offset, 0, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
                        ),
                        const SizedBox(height: 6),
                        Text(item.product.price),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onDecrease,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        onPressed: widget.onIncrease,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
