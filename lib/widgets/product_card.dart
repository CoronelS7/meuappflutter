import "package:flutter/material.dart";
import "package:meu_app_flutter/cores/app_colors.dart";
import "package:meu_app_flutter/widgets/product_image.dart";
import "package:meu_app_flutter/widgets/rating_stars_badge.dart";

class ProductCard extends StatelessWidget {
  final String image;
  final String name;
  final String price;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final double averageRating;
  final int totalReviews;
  final double imageHeight;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry contentPadding;
  final double titleFontSize;
  final double priceFontSize;
  final double buttonFontSize;
  final EdgeInsetsGeometry buttonPadding;

  const ProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.onAdd,
    this.onTap,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.imageHeight = 160,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.titleFontSize = 16,
    this.priceFontSize = 14,
    this.buttonFontSize = 16,
    this.buttonPadding = const EdgeInsets.symmetric(vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.16),
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ProductImage(
                  image: image,
                  width: double.infinity,
                  height: imageHeight,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: contentPadding,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: contentPadding,
                child: RatingStarsBadge(
                  average: averageRating,
                  totalReviews: totalReviews,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: contentPadding,
                child: Text(
                  price,
                  style: TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary300,
                      foregroundColor: Colors.white,
                      padding: buttonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Adicionar",
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
