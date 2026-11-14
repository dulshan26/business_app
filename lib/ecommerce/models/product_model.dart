import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:own/getxpac/sales_item/product_Option_Handler/product_opiton_model.dart';
import 'package:own/getxpac/sales_item/product_Option_Handler/product_variant_model.dart';
import 'package:own/getxpac/sales_item/product_Option_Handler/stock_option_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;

  // Retained while older screens and Firestore documents use item-level values.
  final double price;
  final int stock;

  final List<String> images;
  final String category;
  final bool isActive;
  final List<ProductOptionModel> options;
  final List<ProductVariantModel> variants;
  final List<StockOptionModel> nestedOptions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.stock,
    required this.isActive,
    List<ProductOptionModel> options = const [],
    List<ProductVariantModel> variants = const [],
    List<StockOptionModel> nestedOptions = const [],
    this.createdAt,
    this.updatedAt,
  }) : options = List.unmodifiable(options),
       nestedOptions = List.unmodifiable(nestedOptions),
       variants = List.unmodifiable(
         variants.isEmpty
             ? [
                 ProductVariantModel(
                   id: 'default',
                   attributes: const {},
                   sku: '',
                   price: price,
                   stock: stock,
                   isActive: isActive,
                 ),
               ]
             : variants,
       );

  /// True only when the customer must select option values.
  bool get hasVariants => options.isNotEmpty;

  List<ProductVariantModel> get activeVariants =>
      variants.where((variant) => variant.isActive).toList();

  double? get startingPrice {
    final activePrices = activeVariants.map((variant) => variant.price);
    if (activePrices.isEmpty) return null;
    return activePrices.reduce((first, next) => first < next ? first : next);
  }

  int get totalVariantStock {
    if (nestedOptions.isNotEmpty) return stock;
    if (variants.isEmpty) return stock;
    return activeVariants.fold(0, (total, variant) => total + variant.stock);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
    if (nestedOptions.isNotEmpty) {
      map['options'] = nestedOptions.map((option) => option.toMap()).toList();
    } else {
      map['options'] = options.map((option) => option.toMap()).toList();
      map['variants'] = variants.map((variant) => variant.toMap()).toList();
    }
    return map;
  }

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    final rawData = snap.data();
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return ProductModel.fromMap(data, id: snap.id);
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final legacyPrice = _asDouble(map['price']);
    final legacyStock = _asInt(map['stock'] ?? map['balance']);
    final isActive = map['isActive'] is bool ? map['isActive'] as bool : true;
    final nestedOptions = _readNestedOptions(map['options']);
    final options = _readOptions(map['options'], nestedOptions: nestedOptions);
    final parsedVariants = _readVariants(map['variants']);
    final variants = parsedVariants.isNotEmpty
        ? parsedVariants
        : _buildNestedVariants(nestedOptions, fallbackPrice: legacyPrice);

    // Older products are represented as a non-selectable default variant.
    return ProductModel(
      id: id ?? map['id']?.toString() ?? '',
      name: (map['name'] ?? map['item_name'])?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: legacyPrice,
      images: _readImages(map['images'], map['main_image']),
      category: map['category']?.toString() ?? '',
      stock: legacyStock,
      isActive: isActive,
      options: options,
      variants: variants,
      nestedOptions: nestedOptions,
      createdAt: _asDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: _asDateTime(map['updatedAt'] ?? map['updated_at']),
    );
  }

  static List<ProductOptionModel> _readOptions(
    dynamic value, {
    required List<StockOptionModel> nestedOptions,
  }) {
    if (value is! Iterable) return const [];
    final nestedByName = {
      for (final option in nestedOptions) option.name: option,
    };
    return value.whereType<Map>().map((rawOption) {
      final option = Map<String, dynamic>.from(rawOption);
      final nestedOption = nestedByName[option['name']?.toString()];
      if (nestedOption != null) {
        return ProductOptionModel(
          name: nestedOption.name,
          values: nestedOption.variants.map((variant) => variant.name).toList(),
        );
      }
      return ProductOptionModel.fromMap(option);
    }).toList();
  }

  static List<StockOptionModel> _readNestedOptions(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .where((option) => option['variants'] is Iterable)
        .map(
          (option) =>
              StockOptionModel.fromMap(Map<String, dynamic>.from(option)),
        )
        .toList();
  }

  static List<ProductVariantModel> _buildNestedVariants(
    List<StockOptionModel> options, {
    required double fallbackPrice,
  }) {
    if (options.isEmpty || options.any((option) => option.variants.isEmpty)) {
      return const [];
    }

    final variants = <ProductVariantModel>[];
    void addCombinations(
      int optionIndex,
      Map<String, String> attributes,
      double price,
      int stock,
    ) {
      if (optionIndex == options.length) {
        variants.add(
          ProductVariantModel(
            id: attributes.entries
                .map((entry) => '${entry.key}=${entry.value}')
                .join('::'),
            attributes: Map.unmodifiable(attributes),
            sku: '',
            price: price,
            stock: stock,
            isActive: true,
          ),
        );
        return;
      }

      final option = options[optionIndex];
      for (final variant in option.variants) {
        addCombinations(
          optionIndex + 1,
          {...attributes, option.name: variant.name},
          price + (variant.price ?? fallbackPrice),
          stock < variant.stock ? stock : variant.stock,
        );
      }
    }

    addCombinations(0, const {}, 0, 0x7fffffff);
    return variants;
  }

  static List<ProductVariantModel> _readVariants(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map(
          (variant) =>
              ProductVariantModel.fromMap(Map<String, dynamic>.from(variant)),
        )
        .toList();
  }

  static List<String> _readImages(dynamic images, dynamic mainImage) {
    final result = <String>[];
    if (images is Iterable) {
      result.addAll(
        images.where((image) => image != null).map((image) => image.toString()),
      );
    }
    if (mainImage is String &&
        mainImage.isNotEmpty &&
        !result.contains(mainImage)) {
      result.insert(0, mainImage);
    }
    return result;
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
