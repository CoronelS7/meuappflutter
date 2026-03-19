import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app_flutter/data/cart_data.dart';
import 'package:meu_app_flutter/models/product.dart';

void main() {
  setUp(() {
    CartData.clear();
  });

  tearDown(() {
    CartData.clear();
  });

  test('CartData badgeCount acompanha a quantidade total de itens', () {
    const product = Product(
      image: 'assets/imagens/hamburger_simples.png',
      name: 'Hamburguer Simples',
      price: 'R\$ 12,50',
      description: 'Item de teste',
      category: 'Lanches',
    );

    CartData.addProduct(product);
    CartData.addProduct(product);

    expect(CartData.items, hasLength(1));
    expect(CartData.items.first.quantity, 2);
    expect(CartData.badgeCount.value, 2);

    CartData.decrease(0);

    expect(CartData.items.first.quantity, 1);
    expect(CartData.badgeCount.value, 1);
  });
}
