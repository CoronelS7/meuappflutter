import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';

class Product {
  final String id;
  final String image;
  final String name;
  final String price;
  final String description;
  final String category;
  final String status;
  final bool available;
  final bool featured;
  final bool promotion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id = '',
    required this.image,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    this.status = '',
    this.available = true,
    this.featured = false,
    this.promotion = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Product(
      id: doc.id,
      image: (data['image'] as String? ?? '').trim(),
      name: (data['name'] as String? ?? '').trim(),
      price: _formatPrice(data['price']),
      description: (data['description'] as String? ?? '').trim(),
      category: (data['category'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? '').trim(),
      available: data['available'] as bool? ?? true,
      featured: data['featured'] as bool? ?? false,
      promotion: data['promotion'] as bool? ?? false,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  bool get hasRemoteImage {
    final normalized = image.toLowerCase();
    return normalized.startsWith('http://') || normalized.startsWith('https://');
  }

  bool matchesCategory(String selectedCategory) {
    return normalizeCategory(category) == normalizeCategory(selectedCategory);
  }

  bool get isVisible {
    final normalizedStatus = normalizeText(status);
    final statusAllowsDisplay =
        normalizedStatus.isEmpty ||
        normalizedStatus == 'disponivel' ||
        normalizedStatus == 'available';

    return available && statusAllowsDisplay;
  }

  static String normalizeCategory(String value) {
    switch (normalizeText(value)) {
      case 'burgers':
      case 'burger':
      case 'lanches':
      case 'lanche':
        return 'lanches';
      case 'acompanhamentos':
      case 'acompanhamento':
      case 'sides':
      case 'side':
        return 'acompanhamentos';
      case 'saudaveis':
      case 'saudavel':
      case 'healthy':
      case 'healthyfood':
        return 'saudaveis';
      case 'sobremesas':
      case 'sobremesa':
      case 'desserts':
      case 'dessert':
        return 'sobremesas';
      case 'bebidas':
      case 'bebida':
      case 'drinks':
      case 'drink':
        return 'bebidas';
      case 'combos':
      case 'combo':
        return 'combos';
      default:
        return normalizeText(value);
    }
  }

  static String displayCategory(String value) {
    switch (normalizeCategory(value)) {
      case 'lanches':
        return 'Lanches';
      case 'acompanhamentos':
        return 'Acompanhamentos';
      case 'saudaveis':
        return 'Saudaveis';
      case 'sobremesas':
        return 'Sobremesas';
      case 'bebidas':
        return 'Bebidas';
      case 'combos':
        return 'Combos';
      default:
        final trimmed = value.trim();
        return trimmed.isEmpty ? 'Outros' : trimmed;
    }
  }

  static String normalizeText(String value) {
    return removeDiacritics(value).toLowerCase().trim();
  }

  static String _formatPrice(dynamic value) {
    double priceValue;

    if (value is num) {
      priceValue = value.toDouble();
    } else if (value is String) {
      var normalized = value.replaceAll('R\$', '').replaceAll(' ', '');
      if (normalized.contains(',') && normalized.contains('.')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else if (normalized.contains(',')) {
        normalized = normalized.replaceAll(',', '.');
      }
      priceValue = double.tryParse(normalized) ?? 0;
    } else {
      priceValue = 0;
    }

    return 'R\$ ${priceValue.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
