class ProductOptionVariantModel {
  final String name;
  final double? price;
  final int stock;

  const ProductOptionVariantModel({
    required this.name,
    required this.stock,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'stock': stock};
  }

  factory ProductOptionVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductOptionVariantModel(
      name: (map['name'] ?? map['value'])?.toString() ?? '',
      price: _asDouble(map['price']),
      stock: _asInt(map['stock']),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
