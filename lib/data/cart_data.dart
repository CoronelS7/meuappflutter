import 'package:flutter/material.dart';
import 'package:meu_app_flutter/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

class CartData {
  static final List<CartItem> items = [];

  // 🔔 Notificador do total de itens (badge)
  static final ValueNotifier<int> badgeCount = ValueNotifier<int>(0);

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

  static void addProduct(Product product) {
    final index = items.indexWhere((item) => item.product.name == product.name);

    if (index >= 0) {
      items[index].quantity++;
    } else {
      items.add(CartItem(product: product));
    }
    _syncBadge();
  }

  static void clear() {
    items.clear();
    _syncBadge();
  }

  static void increase(int index) {
    items[index].quantity++;
    _syncBadge();
  }

  static void decrease(int index) {
    if (items[index].quantity > 1) {
      items[index].quantity--;
    } else {
      items.removeAt(index);
    }
    _syncBadge();
  }
}
