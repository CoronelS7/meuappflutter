import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductRatingSummary {
  final double average;
  final int totalReviews;

  const ProductRatingSummary({
    required this.average,
    required this.totalReviews,
  });

  const ProductRatingSummary.empty() : average = 0, totalReviews = 0;
}

class ProductRatingRepository {
  ProductRatingRepository._();

  static final ProductRatingRepository _instance = ProductRatingRepository._();

  factory ProductRatingRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('product_reviews');

  Stream<Map<String, ProductRatingSummary>> watchSummariesByProduct() {
    return _reviewsRef.snapshots().map(_parseSummaries);
  }

  Future<void> submitReview({
    required String productId,
    required int stars,
    String? comment,
    String? productName,
  }) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      throw ArgumentError('productId vazio');
    }

    final normalizedStars = stars.clamp(1, 5);
    final normalizedComment = (comment ?? '').trim();
    final user = _auth.currentUser;

    await _reviewsRef.add({
      'productId': normalizedProductId,
      'productName': (productName ?? '').trim(),
      'stars': normalizedStars,
      'comment': normalizedComment,
      'userId': user?.uid ?? '',
      'userName': (user?.displayName ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, ProductRatingSummary> _parseSummaries(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productId = (data['productId'] as String? ?? '').trim();
      if (productId.isEmpty) {
        continue;
      }

      final stars = _toDouble(data['stars']);
      if (stars < 1 || stars > 5) {
        continue;
      }

      sums[productId] = (sums[productId] ?? 0) + stars;
      counts[productId] = (counts[productId] ?? 0) + 1;
    }

    final result = <String, ProductRatingSummary>{};
    for (final entry in counts.entries) {
      final productId = entry.key;
      final total = entry.value;
      final sum = sums[productId] ?? 0;

      result[productId] = ProductRatingSummary(
        average: total == 0 ? 0 : (sum / total),
        totalReviews: total,
      );
    }

    return result;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }
}
