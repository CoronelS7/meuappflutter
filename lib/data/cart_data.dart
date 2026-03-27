import 'package:flutter/material.dart';
import 'package:meu_app_flutter/models/product.dart';

class CartAdditionalSelection {
  final ProductAdditional additional;
  final int quantity;

  const CartAdditionalSelection({
    required this.additional,
    required this.quantity,
  });

  String get label => '${additional.name} x$quantity';

  double get totalPrice => Product.parsePrice(additional.price) * quantity;
}

class CartItem {
  final Product product;
  final List<CartAdditionalSelection> selectedAdditionals;
  final String comment;
  int quantity;

  CartItem({
    required this.product,
    this.selectedAdditionals = const [],
    this.comment = '',
    this.quantity = 1,
  });

  bool get hasAdditionals => selectedAdditionals.isNotEmpty;
  bool get hasComment => comment.trim().isNotEmpty;

  String get additionalsLabel =>
      selectedAdditionals.map((item) => item.label).join(', ');

  String get displayName {
    if (!hasAdditionals) {
      return product.name;
    }

    return '${product.name} ($additionalsLabel)';
  }

  double get unitPrice {
    final additionalsTotal = selectedAdditionals.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return Product.parsePrice(product.price) + additionalsTotal;
  }

  String get unitPriceText => Product.formatPrice(unitPrice);

  bool matches(
    Product otherProduct,
    List<CartAdditionalSelection> additionals,
    String otherComment,
  ) {
    final sameProduct = product.id.isNotEmpty && otherProduct.id.isNotEmpty
        ? product.id == otherProduct.id
        : product.name == otherProduct.name;

    return sameProduct &&
        _sameAdditionals(selectedAdditionals, additionals) &&
        comment.trim() == otherComment.trim();
  }

  static bool _sameAdditionals(
    List<CartAdditionalSelection> first,
    List<CartAdditionalSelection> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var i = 0; i < first.length; i++) {
      if (first[i].additional.name != second[i].additional.name ||
          first[i].additional.price != second[i].additional.price ||
          first[i].quantity != second[i].quantity) {
        return false;
      }
    }

    return true;
  }
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
  static void addProduct(
    Product product, {
    List<CartAdditionalSelection> selectedAdditionals = const [],
    String comment = '',
  }) {
    final normalizedAdditionals = List<CartAdditionalSelection>.unmodifiable(
      selectedAdditionals,
    );
    final normalizedComment = comment.trim();
    final index = items.indexWhere(
      (item) => item.matches(product, normalizedAdditionals, normalizedComment),
    );

    if (index >= 0) {
      items[index].quantity++;
    } else {
      items.add(
        CartItem(
          product: product,
          selectedAdditionals: normalizedAdditionals,
          comment: normalizedComment,
        ),
      );
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
