import 'package:flutter/material.dart';
import 'package:meu_app_flutter/models/product.dart';
import 'package:meu_app_flutter/widgets/product_image.dart';
import 'package:meu_app_flutter/widgets/rating_stars_badge.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final double averageRating;
  final int totalReviews;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.averageRating = 0,
    this.totalReviews = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductImage(
                image: product.image,
                fit: BoxFit.cover,
                width: double.infinity,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            RatingStarsBadge(
              average: averageRating,
              totalReviews: totalReviews,
            ),
          ],
        ),
      ),
    );
  }
}
