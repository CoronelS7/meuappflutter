import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/data/notificacoes_data.dart';
import 'package:meu_app_flutter/data/product_rating_repository.dart';
import 'package:meu_app_flutter/data/products_repository.dart';
import 'package:meu_app_flutter/models/product.dart';
import 'package:meu_app_flutter/screens/notificacoes_screen.dart';
import 'package:meu_app_flutter/screens/product_details_screen.dart';
import 'package:meu_app_flutter/widgets/home_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductsRepository _productsRepository = ProductsRepository();
  final ProductRatingRepository _productRatingRepository =
      ProductRatingRepository();

  static const List<String> _categories = [
    'Lanches',
    'Acompanhamentos',
    'Saudaveis',
    'Sobremesas',
    'Bebidas',
    'Combos',
  ];

  String? _categoriaSelecionada;
  String _busca = '';

  String _normalizar(String texto) {
    return removeDiacritics(texto).toLowerCase().trim();
  }

  List<Product> _produtosFiltrados(List<Product> products) {
    final buscaNormalizada = _normalizar(_busca);

    final filtrados = products.where((product) {
      final nome = _normalizar(product.name);
      final categoria = Product.normalizeCategory(product.category);
      final categoriaOriginal = _normalizar(product.category);

      final matchCategoria = _categoriaSelecionada == null
          ? true
          : categoria == Product.normalizeCategory(_categoriaSelecionada!);

      final matchBusca = buscaNormalizada.isEmpty
          ? true
          : nome.contains(buscaNormalizada) ||
                categoria.contains(buscaNormalizada) ||
                categoriaOriginal.contains(buscaNormalizada);

      return matchCategoria && matchBusca;
    }).toList();

    if (_categoriaSelecionada == null && buscaNormalizada.isEmpty) {
      return filtrados.where((product) => product.featured).toList();
    }

    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primary300, toolbarHeight: 5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCategories(),
            const SizedBox(height: 16),
            _buildPopularTitle(),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Product>>(
                initialData: _productsRepository.cachedProducts,
                stream: _productsRepository.watchProducts(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildStateMessage(
                      'Nao foi possivel carregar os produtos.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final produtos = _produtosFiltrados(snapshot.data ?? []);
                  return StreamBuilder<Map<String, ProductRatingSummary>>(
                    initialData: const <String, ProductRatingSummary>{},
                    stream: _productRatingRepository.watchSummariesByProduct(),
                    builder: (context, ratingSnapshot) {
                      final summaries = ratingSnapshot.data ?? const {};
                      return _buildPopularGrid(produtos, summaries);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        boxShadow: [
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
        color: AppColors.primary300,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pedido Facil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificacoesScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ValueListenableBuilder<int>(
                    valueListenable: NotificacoesData.unreadListenable,
                    builder: (context, unreadCount, child) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SvgPicture.asset(
                            'assets/icones/notifications.svg',
                            width: 30,
                            height: 30,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _busca = value;
                });
              },
              decoration: InputDecoration(
                icon: SvgPicture.asset(
                  'assets/icones/search.svg',
                  width: 24,
                  height: 24,
                ),
                hintText: 'Vai pedir o que hoje?',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.gray300,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorias',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _categoriaSelecionada == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _categoriaSelecionada = isSelected ? null : category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary300
                          : Colors.transparent,
                      border: Border.all(color: AppColors.primary600),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isSelected ? Colors.white : AppColors.primary600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTitle() {
    if (_busca.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Resultados para "$_busca"',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        _categoriaSelecionada ?? 'Populares',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPopularGrid(
    List<Product> products,
    Map<String, ProductRatingSummary> ratingsByProduct,
  ) {
    if (products.isEmpty) {
      return _buildStateMessage('Nenhum item encontrado');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          final rating =
              ratingsByProduct[product.id] ??
              const ProductRatingSummary.empty();

          return ProductCard(
            product: product,
            averageRating: rating.average,
            totalReviews: rating.totalReviews,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStateMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: AppColors.gray400,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
