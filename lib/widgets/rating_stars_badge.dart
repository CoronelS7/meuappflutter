import 'package:flutter/material.dart';

class RatingStarsBadge extends StatelessWidget {
  final double average;
  final int totalReviews;

  const RatingStarsBadge({
    super.key,
    required this.average,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final hasRating = totalReviews > 0 && average > 0;
    final text = hasRating ? average.toStringAsFixed(1) : 'Novo';
    final details = hasRating ? '($totalReviews)' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: hasRating ? Colors.black87 : Colors.green,
          ),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            details,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}
