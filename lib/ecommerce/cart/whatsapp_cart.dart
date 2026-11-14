String generateWhatsAppMessage({
  required String name,
  required String address,
  required List<Map<String, dynamic>> cartItems,
  required double subTotal,
  required double deliveryFee,
}) {
  StringBuffer buffer = StringBuffer();

  buffer.writeln("🔔 *NEW ORDER RECEIVED* 🔔\n");
  buffer.writeln("👤 *Customer Details:*");
  buffer.writeln("• Name: $name");
  buffer.writeln("• Address: $address\n");

  buffer.writeln("🛒 *Items:*");
  for (var item in cartItems) {
    String itemName = item['item_name'] ?? 'Unknown Item';
    int qty = item['quantity'] ?? 0;
    double price = item['price'] ?? 0.0;
    double totalItemPrice = price * qty;
    final rawAttributes = item['selectedAttributes'];
    final attributes = rawAttributes is Map
        ? rawAttributes.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(', ')
        : '';
    buffer.writeln(
      "- $itemName${attributes.isEmpty ? '' : ' ($attributes)'} "
      "(x$qty) - LKR ${totalItemPrice.toStringAsFixed(2)}",
    );
  }

  double finalTotal = subTotal + deliveryFee;

  buffer.writeln("\n💵 *Subtotal:* LKR ${subTotal.toStringAsFixed(2)}");
  buffer.writeln("🚚 *Delivery Fee:* LKR ${deliveryFee.toStringAsFixed(2)}");
  buffer.writeln("💰 *Total Amount:* LKR ${finalTotal.toStringAsFixed(2)}");
  buffer.writeln("\nThank you for shopping with us! 🙌");

  return buffer.toString();
}
