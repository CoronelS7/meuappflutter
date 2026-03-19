import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/cart_data.dart';
import 'package:meu_app_flutter/data/notificacoes_data.dart';
import 'package:meu_app_flutter/screens/login.dart';
import 'package:meu_app_flutter/screens/metodo_pagamento.dart';
import 'package:meu_app_flutter/stripe/checkout_service.dart';
import 'package:meu_app_flutter/stripe/customer_identity_service.dart';
import 'package:meu_app_flutter/stripe/stripe_config.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final CheckoutService _checkoutService = const CheckoutService();
  final CustomerIdentityService _customerIdentityService =
      CustomerIdentityService();

  StreamSubscription<User?>? _authSubscription;
  MetodoPagamento? _metodoPagamento;
  String? _metodoPagamentoResumo;
  bool _saveCard = false;
  bool _isProcessingCheckout = false;
  bool _isLogado = false;

  @override
  void initState() {
    super.initState();

    _isLogado = FirebaseAuth.instance.currentUser != null;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLogado = user != null;
        if (!_isLogado) {
          _metodoPagamento = null;
          _metodoPagamentoResumo = null;
          _saveCard = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
    var sum = 0.0;
    for (final item in CartData.items) {
      sum += _parsePrice(item.product.price) * item.quantity;
    }
    return sum;
  }

  int get _amountInCents => (_total * 100).round();

  String _formatBRL(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $fixed';
  }

  String get _metodoPagamentoTexto {
    if (_metodoPagamentoResumo != null && _metodoPagamentoResumo!.isNotEmpty) {
      return _metodoPagamentoResumo!;
    }

    switch (_metodoPagamento) {
      case MetodoPagamento.googlePay:
        return 'Google Pay';
      case MetodoPagamento.pix:
        return 'PIX';
      case MetodoPagamento.cartao:
        return 'Cartao';
      default:
        return 'Escolher >';
    }
  }

  String get _checkoutDescription {
    final names = CartData.items
        .map((item) => item.product.name)
        .take(3)
        .toList(growable: false);

    final base = names.join(', ');
    if (CartData.items.length > 3) {
      final extras = CartData.items.length - 3;
      return 'Pedido Facil: $base +$extras itens';
    }

    return 'Pedido Facil: $base';
  }

  List<NotificationOrderItem> _buildNotificationItems() {
    return CartData.items
        .map(
          (item) => NotificationOrderItem(
            nome: item.product.name,
            imagem: item.product.image,
            quantidade: item.quantity,
            precoUnitario: _parsePrice(item.product.price),
          ),
        )
        .toList(growable: false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearCart() {
    setState(() {
      CartData.clear();
      _metodoPagamento = null;
      _metodoPagamentoResumo = null;
      _saveCard = false;
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

  void _removeItem(int index) {
    setState(() {
      CartData.remove(index);
      if (CartData.items.isEmpty) {
        _metodoPagamento = null;
        _metodoPagamentoResumo = null;
        _saveCard = false;
      }
    });
  }

  Future<void> _irParaLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _selectPaymentMethod() async {
    if (_isProcessingCheckout) {
      return;
    }

    if (!_isLogado) {
      await _irParaLogin();
      return;
    }

    final result = await Navigator.push<MetodoPagamentoSelecao>(
      context,
      MaterialPageRoute(builder: (_) => const MetodoPagamentoScreen()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _metodoPagamento = result.metodo;
      _metodoPagamentoResumo = result.resumo;
      if (_metodoPagamento != MetodoPagamento.cartao) {
        _saveCard = false;
      }
    });
  }

  Future<void> _handleCheckout() async {
    if (CartData.items.isEmpty || _isProcessingCheckout) {
      return;
    }

    if (!_isLogado) {
      await _irParaLogin();
      return;
    }

    if (_metodoPagamento == null) {
      _showSnackBar('Selecione um metodo de pagamento antes de finalizar.');
      return;
    }

    if (_metodoPagamento != MetodoPagamento.cartao) {
      _showSnackBar('Somente cartao via Stripe esta integrado no momento.');
      return;
    }

    if (StripeConfig.publishableKey.isEmpty) {
      _showSnackBar(
        'Defina STRIPE_PUBLISHABLE_KEY para abrir o checkout Stripe.',
      );
      return;
    }

    final totalPedido = _total;
    final itensPedido = _buildNotificationItems();

    setState(() {
      _isProcessingCheckout = true;
    });

    try {
      final customerKey = await _customerIdentityService.getOrCreateCustomerKey();
      await _checkoutService.startCheckout(
        customerKey: customerKey,
        saveCard: _saveCard,
        amountInCents: _amountInCents,
        description: _checkoutDescription,
      );

      if (!mounted) {
        return;
      }

      NotificacoesData.adicionarPedidoFinalizado(
        quantidadeItens: CartData.totalItems,
        total: totalPedido,
        itens: itensPedido,
      );

      setState(() {
        CartData.clear();
        _metodoPagamento = null;
        _metodoPagamentoResumo = null;
        _saveCard = false;
      });
      _showSnackBar('Pagamento concluido com sucesso.');
    } on StripeException catch (error) {
      _showSnackBar(
        error.error.localizedMessage ?? 'Pagamento cancelado pelo usuario.',
      );
    } on CheckoutException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Falha ao abrir o checkout com Stripe.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCheckout = false;
        });
      }
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
            onPressed: isEmpty || _isProcessingCheckout ? null : _clearCart,
            child: Text(
              'Limpar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isEmpty || _isProcessingCheckout
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey.shade400,
                      ),
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
                        onDelete: _isProcessingCheckout
                            ? null
                            : () => _removeItem(index),
                        onIncrease: _isProcessingCheckout
                            ? null
                            : () => _increaseQty(index),
                        onDecrease: _isProcessingCheckout
                            ? null
                            : () => _decreaseQty(index),
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
    final loginRequired = !_isLogado;
    final canCheckout = !loginRequired && !isEmpty && !_isProcessingCheckout;

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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: isEmpty ? null : _selectPaymentMethod,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Metodo Pagamento',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                Text(
                  loginRequired ? 'Faca login >' : _metodoPagamentoTexto,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: loginRequired ? Colors.red : AppColors.primary300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_metodoPagamento == MetodoPagamento.cartao && _isLogado) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD9E8E2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _saveCard,
                    activeColor: AppColors.primary300,
                    onChanged: _isProcessingCheckout
                        ? null
                        : (value) {
                            setState(() {
                              _saveCard = value ?? false;
                            });
                          },
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salvar cartao para proximas compras',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Se o pagamento for concluido, o cartao fica disponivel no fluxo da Stripe para este cliente.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEmpty || _isProcessingCheckout
                    ? AppColors.gray300
                    : AppColors.primary300,
              ),
              onPressed: isEmpty || _isProcessingCheckout
                  ? null
                  : (loginRequired ? _irParaLogin : _handleCheckout),
              child: _isProcessingCheckout
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      loginRequired
                          ? 'Entrar para finalizar'
                          : canCheckout
                              ? 'Finalizar Pedido'
                              : 'Finalizar Pedido',
                      style: const TextStyle(
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
    );
  }
}

class CartItemWidget extends StatefulWidget {
  const CartItemWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  double offset = 0;
  final double maxDrag = -80;

  bool get _canSwipe => widget.onDelete != null;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_canSwipe) {
      return;
    }

    setState(() {
      offset += details.delta.dx;
      if (offset < maxDrag) {
        offset = maxDrag;
      }
      if (offset > 0) {
        offset = 0;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_canSwipe) {
      return;
    }

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
              child: Icon(
                Icons.delete,
                color: widget.onDelete == null
                    ? AppColors.gray300
                    : Colors.red.shade400,
              ),
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
                        onPressed: widget.onDecrease,
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
