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

  static void addProduct(Product product) {
    final index =
        items.indexWhere((item) => item.product.name == product.name);

    if (index >= 0) {
      items[index].quantity++;
    } else {
      items.add(CartItem(product: product));
    }
  }
}
