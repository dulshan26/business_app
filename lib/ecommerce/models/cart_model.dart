class CartItem {
  final String itemId;
  final String variantId;
  final String productName;
  final String productImage;
  final Map<String, String> selectedAttributes;
  final String sku;
  final double unitPrice;
  int quantity;

  CartItem({
    String? id,
    String? itemId,
    String? name,
    String? productName,
    double? price,
    double? unitPrice,
    String? imageUrl,
    String? productImage,
    this.variantId = 'default',
    Map<String, String> selectedAttributes = const {},
    this.sku = '',
    this.quantity = 1,
  }) : itemId = itemId ?? id ?? '',
       productName = productName ?? name ?? '',
       productImage = productImage ?? imageUrl ?? '',
       unitPrice = unitPrice ?? price ?? 0,
       selectedAttributes = Map.unmodifiable(selectedAttributes);

  // Legacy aliases keep older UI references source-compatible.
  String get id => itemId;
  String get name => productName;
  String get imageUrl => productImage;
  double get price => unitPrice;
  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'variantId': variantId,
      'productName': productName,
      'productImage': productImage,
      'selectedAttributes': selectedAttributes,
      'sku': sku,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final rawAttributes = map['selectedAttributes'] ?? map['attributes'];
    final attributes = <String, String>{};
    if (rawAttributes is Map) {
      rawAttributes.forEach((key, value) {
        if (value != null) attributes[key.toString()] = value.toString();
      });
    }

    return CartItem(
      itemId: (map['itemId'] ?? map['id'])?.toString(),
      variantId: map['variantId']?.toString() ?? 'default',
      productName:
          (map['productName'] ?? map['name'] ?? map['item_name'])?.toString() ??
          '',
      productImage:
          (map['productImage'] ??
                  map['imageUrl'] ??
                  map['main_image'] ??
                  map['image'])
              ?.toString() ??
          '',
      selectedAttributes: attributes,
      sku: map['sku']?.toString() ?? '',
      unitPrice: _asDouble(map['unitPrice'] ?? map['price']),
      quantity: _asInt(map['quantity'], fallback: 1),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
