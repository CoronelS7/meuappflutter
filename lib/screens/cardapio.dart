import "package:flutter/material.dart";
import "package:meu_app_flutter/cores/app_colors.dart";
import "package:meu_app_flutter/data/cart_data.dart";
import "package:meu_app_flutter/data/products_repository.dart";
import "package:meu_app_flutter/models/product.dart";
import "package:meu_app_flutter/screens/carrinho.dart";
import "package:meu_app_flutter/screens/product_details_screen.dart";
import "package:meu_app_flutter/widgets/product_card.dart";

class CardapioScreen extends StatelessWidget {
  const CardapioScreen({super.key});

  static const List<String> _sections = [
    'Lanches',
    'Acompanhamentos',
    'Saudaveis',
    'Sobremesas',
    'Bebidas',
    'Combos',
  ];

  @override
  Widget build(BuildContext context) {
    final productsRepository = ProductsRepository();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.16,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primary300,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.19),
                  offset: Offset(0, 10),
                  blurRadius: 20,
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.23),
                  offset: Offset(0, 6),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const SafeArea(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cardapio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              initialData: productsRepository.cachedProducts,
              stream: productsRepository.watchProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Nao foi possivel carregar o cardapio.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.gray400,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum produto disponivel no momento.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.gray400,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final double cardWidth = width < 800 ? width * 0.5 : 280;

                      final sections = _sections
                          .map(
                            (title) => (
                              title: title,
                              items: products
                                  .where((product) => product.matchesCategory(title))
                                  .toList(),
                            ),
                          )
                          .where((section) => section.items.isNotEmpty)
                          .toList();

                      if (sections.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Nenhum produto disponivel no momento.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.gray400,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final section in sections)
                            _ProductSection(
                              title: section.title,
                              items: section.items,
                              cardWidth: cardWidth,
                              itemsPerRow: 6,
                            ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final String title;
  final List<Product> items;
  final double cardWidth;
  final int itemsPerRow;

  const _ProductSection({
    required this.title,
    required this.items,
    required this.cardWidth,
    required this.itemsPerRow,
  });

  List<List<Product>> _chunk(List<Product> list, int size) {
    final chunks = <List<Product>>[];
    for (int i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _chunk(items, itemsPerRow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          _CarouselRow(rowItems: rows[rowIndex], cardWidth: cardWidth),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CarouselRow extends StatelessWidget {
  final List<Product> rowItems;
  final double cardWidth;

  const _CarouselRow({required this.rowItems, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rowItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = rowItems[index];

          return SizedBox(
            width: cardWidth,
            child: ProductCard(
              image: product.image,
              name: product.name,
              price: product.price,
              onAdd: () {
                CartData.addProduct(product);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CarrinhoScreen(),
                  ),
                );
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailsScreen(product: product),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
