import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meu_app_flutter/models/product.dart';

class ProductsRepository {
  ProductsRepository._();

  static final ProductsRepository _instance = ProductsRepository._();

  factory ProductsRepository() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _cachedProducts = const [];

  List<Product> get cachedProducts => List<Product>.unmodifiable(_cachedProducts);
  bool get hasCachedProducts => _cachedProducts.isNotEmpty;

  Future<List<Product>> preloadProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get(
        const GetOptions(source: Source.serverAndCache),
      );
      return _cacheSnapshot(snapshot.docs);
    } on FirebaseException {
      final snapshot = await _firestore.collection('products').get(
        const GetOptions(source: Source.cache),
      );
      return _cacheSnapshot(snapshot.docs);
    }
  }

  Stream<List<Product>> watchProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return _cacheSnapshot(snapshot.docs);
    });
  }

  List<Product> _cacheSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final products = docs
        .map(Product.fromFirestore)
        .where((product) => product.isVisible)
        .toList();

    products.sort(_compareProducts);
    _cachedProducts = List<Product>.unmodifiable(products);
    return _cachedProducts;
  }

  int _compareProducts(Product a, Product b) {
    final featuredCompare = _boolDescending(a.featured, b.featured);
    if (featuredCompare != 0) {
      return featuredCompare;
    }

    final promotionCompare = _boolDescending(a.promotion, b.promotion);
    if (promotionCompare != 0) {
      return promotionCompare;
    }

    final updatedCompare = _dateDescending(a.updatedAt, b.updatedAt);
    if (updatedCompare != 0) {
      return updatedCompare;
    }

    final createdCompare = _dateDescending(a.createdAt, b.createdAt);
    if (createdCompare != 0) {
      return createdCompare;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _boolDescending(bool a, bool b) {
    if (a == b) {
      return 0;
    }

    return a ? -1 : 1;
  }

  int _dateDescending(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }

    return b.compareTo(a);
  }
}
