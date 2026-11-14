import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_Option_Handler/product_option_variant_model.dart';
import 'product_Option_Handler/stock_option_model.dart';

export 'product_Option_Handler/product_opiton_model.dart';
export 'product_Option_Handler/product_option_variant_model.dart';
export 'product_Option_Handler/product_variant_model.dart';
export 'product_Option_Handler/stock_option_model.dart';

class ItemModel {
  final String id;
  final String name;
  final String description;

  //keep this untill full turn over
  final double price;
  final int stock;

  final List<String> images;
  final String category;
  final bool isActive;

  final List<StockOptionModel> options;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    required this.category,
    required this.isActive,
    required List<StockOptionModel> options,
    this.createdAt,
    this.updatedAt,
  }) : options = List.unmodifiable(options);

  List<ProductOptionVariantModel> get variants =>
      options.expand((option) => option.variants).toList();

  bool get hasVariants => variants.isNotEmpty;

  List<ProductOptionVariantModel> get activeVariants => variants;

  double? get startingPrice => price;

  int get totalVariantStock {
    if (!hasVariants) return stock;
    return activeVariants.fold(0, (total, variant) => total + variant.stock);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'images': images,
      'category': category,
      'isActive': isActive,

      'options': options.map((o) => o.toMap()).toList(),

      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ItemModel.fromSnapshot(DocumentSnapshot snap) {
    final rawData = snap.data();
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return ItemModel.fromMap(data, id: snap.id);
  }

  factory ItemModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final legacyVariants = _readLegacyVariants(data['variants']);
    final parsedOptions = _readOptions(
      data['options'],
      legacyVariants: legacyVariants,
    );
    final legacyPrice = _asDouble(data['price']);
    final legacyStock = _asInt(data['stock'] ?? data['balance']);
    return ItemModel(
      id: id ?? data['id']?.toString() ?? '',
      name: (data['name'] ?? data['item_name'])?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: legacyPrice,
      stock: legacyStock,
      images: _readStrings(data['images']),
      category: data['category']?.toString() ?? '',
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      options: parsedOptions,
      createdAt: _asDateTime(data['created_at'] ?? data['createdAt']),
      updatedAt: _asDateTime(data['updated_at'] ?? data['updatedAt']),
    );
  }

  static List<StockOptionModel> _readOptions(
    dynamic value, {
    required List<Map<String, dynamic>> legacyVariants,
  }) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map(
          (option) => StockOptionModel.fromMap(
            Map<String, dynamic>.from(option),
            legacyVariants: legacyVariants,
          ),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _readLegacyVariants(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((variant) => Map<String, dynamic>.from(variant))
        .toList();
  }

  static List<String> _readStrings(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .where((entry) => entry != null)
        .map((entry) => entry.toString())
        .toList();
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
