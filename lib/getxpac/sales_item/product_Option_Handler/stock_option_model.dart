import 'product_option_variant_model.dart';

class StockOptionModel {
  final String name;
  final List<ProductOptionVariantModel> variants;

  StockOptionModel({
    required this.name,
    required List<ProductOptionVariantModel> variants,
  }) : variants = List.unmodifiable(variants);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'variants': variants.map((variant) => variant.toMap()).toList(),
    };
  }

  factory StockOptionModel.fromMap(
    Map<String, dynamic> map, {
    Iterable<Map<String, dynamic>> legacyVariants = const [],
  }) {
    final rawVariants = map['variants'];
    if (rawVariants is Iterable) {
      return StockOptionModel(
        name: map['name']?.toString() ?? '',
        variants: rawVariants
            .whereType<Map>()
            .map(
              (variant) => ProductOptionVariantModel.fromMap(
                Map<String, dynamic>.from(variant),
              ),
            )
            .toList(),
      );
    }

    final rawValues = map['values'];
    final name = map['name']?.toString() ?? '';
    return StockOptionModel(
      name: name,
      variants: rawValues is Iterable
          ? rawValues
                .where((value) => value != null)
                .map((value) => value.toString())
                .map(
                  (value) => ProductOptionVariantModel(
                    name: value,
                    price: _legacyPriceForValue(legacyVariants, name, value),
                    stock: _legacyStockForValue(legacyVariants, name, value),
                  ),
                )
                .toList()
          : const [],
    );
  }

  static int _legacyStockForValue(
    Iterable<Map<String, dynamic>> variants,
    String optionName,
    String value,
  ) {
    return variants.fold(0, (total, variant) {
      final attributes = variant['attributes'];
      if (variant['isActive'] == false ||
          attributes is! Map ||
          attributes[optionName]?.toString() != value) {
        return total;
      }

      final stock = variant['stock'];
      if (stock is num) return total + stock.toInt();
      return total + (int.tryParse(stock?.toString() ?? '') ?? 0);
    });
  }

  static double? _legacyPriceForValue(
    Iterable<Map<String, dynamic>> variants,
    String optionName,
    String value,
  ) {
    for (final variant in variants) {
      final attributes = variant['attributes'];
      if (variant['isActive'] == false ||
          attributes is! Map ||
          attributes[optionName]?.toString() != value) {
        continue;
      }

      final price = variant['price'];
      if (price is num) return price.toDouble();
      final parsedPrice = double.tryParse(price?.toString() ?? '');
      if (parsedPrice != null) return parsedPrice;
    }
    return null;
  }
}
