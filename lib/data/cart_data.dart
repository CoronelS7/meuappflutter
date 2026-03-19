import 'package:flutter/material.dart';
import 'package:meu_app_flutter/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartData {
  static final List<CartItem> items = [];

  // 🔔 Notificador do badge
  static final ValueNotifier<int> badgeCount = ValueNotifier<int>(0);

  // ================= TOTAL =================
  static int get totalItems {
    int total = 0;
    for (final item in items) {
      total += item.quantity;
    }
    return total;
  }

  static void _syncBadge() {
    badgeCount.value = totalItems;
  }

  // ================= ADICIONAR =================
  static void addProduct(Product product) {
    final index = items.indexWhere((item) => item.product.name == product.name);

    if (index >= 0) {
      items[index].quantity++;
    } else {
      items.add(CartItem(product: product));
    }

    _syncBadge();
  }

  // ================= AUMENTAR =================
  static void increase(int index) {
    items[index].quantity++;
    _syncBadge();
  }

  // ================= DIMINUIR =================
  static void decrease(int index) {
    if (items[index].quantity > 1) {
      items[index].quantity--;
    } else {
      remove(index);
    }
    _syncBadge();
  }

  // ================= REMOVER (🔥 NOVO) =================
  static void remove(int index) {
    items.removeAt(index);
    _syncBadge();
  }

  // ================= LIMPAR =================
  static void clear() {
    items.clear();
    _syncBadge();
  }
}
