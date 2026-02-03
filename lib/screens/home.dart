import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

import '../data/popular_products.dart';
import '../widgets/home_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            Expanded(child: _buildPopularGrid()),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
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
                  'Pedido Fácil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/icones/notifications.svg',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
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

  // ================= CATEGORIES =================
  Widget _buildCategories() {
    final categories = [
      'Lanches',
      'Acompanhamentos',
      'Saudáveis',
      'Sobremesas',
      'Bebidas',
    ];

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
              children: categories.map((c) {
                return Container(
                  margin: const EdgeInsets.only(right: 8, top: 15),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary600),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.primary600,
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

  // ================= POPULARES =================
  Widget _buildPopularTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Populares',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPopularGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: popularProducts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          return ProductCard(product: popularProducts[index]);
        },
      ),
    );
  }
}
