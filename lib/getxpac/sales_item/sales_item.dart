class SaleItem {
  final String itemId; // 🔥 important
  final String name;
  final int quantity;
  final double price;

  SaleItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}
