class ProductVariantModel {
  final String id;
  final Map<String, String> attributes;
  final String sku;
  final double price;
  final int stock;
  final bool isActive;

  const ProductVariantModel({
    required this.id,
    required this.attributes,
    required this.sku,
    required this.price,
    required this.stock,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attributes': attributes,
      'sku': sku,
      'price': price,
      'stock': stock,
      'isActive': isActive,
    };
  }

  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    final rawAttributes = map['attributes'];
    final attributes = <String, String>{};
    if (rawAttributes is Map) {
      rawAttributes.forEach((key, value) {
        if (value != null) attributes[key.toString()] = value.toString();
      });
    }

    return ProductVariantModel(
      id: map['id']?.toString() ?? '',
      attributes: attributes,
      sku: map['sku']?.toString() ?? '',
      price: _asDouble(map['price']),
      stock: _asInt(map['stock']),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
