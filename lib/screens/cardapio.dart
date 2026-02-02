import "package:flutter/material.dart";
import "package:meu_app_flutter/cores/app_colors.dart";
import "package:meu_app_flutter/widgets/product_card.dart";
import 'package:flutter_svg/flutter_svg.dart';

final List<Map<String, String>> lanches = [
  {
    'image': 'assets/imagens/humberger_simples.png',
    'name': 'Hambúrguer Clássico',
    'price': 'R\$ 24,90',
  },
  {
    'image': 'assets/imagens/humburger_bacon.png',
    'name': 'Hambúrguer com Bacon',
    'price': 'R\$ 29,90',
  },
  {
    'image': 'assets/imagens/humburger_duplo.png',
    'name': 'Hambúrguer Duplo',
    'price': 'R\$ 32,00',
  },
  {
    'image': 'assets/imagens/frango_empanado.png',
    'name': 'Frango Empanado',
    'price': 'R\$ 21,00',
  },
  {
    'image': 'assets/imagens/hot_dog.png',
    'name': 'Hot Dog Especial',
    'price': 'R\$ 18,50',
  },
];

final List<Map<String, String>> acompanhamentos = [
  {
    'image': 'assets/imagens/batata.png',
    'name': 'Batata Frita',
    'price': 'R\$ 12,00',
  },
  {
    'image': 'assets/imagens/onion_rings.png',
    'name': 'Onion Rings',
    'price': 'R\$ 14,00',
  },
  {'image': 'assets/imagens/pudim.png', 'name': 'Pudim', 'price': 'R\$ 9,50'},
  {
    'image': 'assets/imagens/torta_de_limao.png',
    'name': 'Torta de Limão',
    'price': 'R\$ 15,50',
  },
];

class CardapioScreen extends StatelessWidget {
  const CardapioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(color: AppColors.primary300),
          ),

          // HEADER (fixa no topo)
          Container(
            height: 120, // altura da header
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cardápio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTEÚDO COM SCROLL VERTICAL
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: const Text(
                      'Lanches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 260,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        scrollbars: false,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: lanches.length,
                        itemBuilder: (context, index) {
                          final product = lanches[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ProductCard(
                              image: product['image']!,
                              name: product['name']!,
                              price: product['price']!,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 260,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        scrollbars: false,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: lanches.length,
                        itemBuilder: (context, index) {
                          final product = lanches[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ProductCard(
                              image: product['image']!,
                              name: product['name']!,
                              price: product['price']!,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: const Text(
                      'Acompanhamentos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 260,
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(
                        scrollbars: false,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: acompanhamentos.length,
                        itemBuilder: (context, index) {
                          final product = acompanhamentos[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ProductCard(
                              image: product['image']!,
                              name: product['name']!,
                              price: product['price']!,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      selectedItemColor: AppColors.primary600,
      unselectedItemColor: AppColors.gray400,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/porta.svg',
            width: 32,
            height: 32,
          ),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/cardapio.svg',
            width: 32,
            height: 32,
          ),
          label: 'Cardápio',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/store.svg',
            width: 32,
            height: 32,
          ),
          label: 'Carrinho',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icones/profile.svg',
            width: 32,
            height: 32,
          ),
          label: 'Carrinho',
        ),
      ],
    );
  }
}
