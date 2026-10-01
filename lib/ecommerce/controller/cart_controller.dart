import 'package:get/get.dart';

class CartController extends GetxController {
  // Reactive map: { product_id: Map representing product + quantity }
  var cartItems = <String, Map<String, dynamic>>{}.obs;

  // Add product to cart
  void addToCart(Map<String, dynamic> product) {
    String productId = (product['id'] ?? product['item_name']).toString();
    int selectedQty = product['quantity'] ?? 1;
    int maxBalance = product['max_balance'] ?? 999;

    if (cartItems.containsKey(productId)) {
      int currentQty = (cartItems[productId]!['quantity'] as num).toInt();

      if (currentQty + selectedQty <= maxBalance) {
        cartItems[productId]!['quantity'] = currentQty + selectedQty;
      } else {
        cartItems[productId]!['quantity'] = maxBalance;
        Get.snackbar("Stock Limit", "Cannot add more than available stock");
      }
    } else {
      // Create a map copy to safely add & track 'quantity'
      Map<String, dynamic> itemToAdd = Map<String, dynamic>.from(product);
      itemToAdd['quantity'] = selectedQty;
      cartItems[productId] = itemToAdd;
    }

    cartItems.refresh();
  }

  // Decrease product quantity or remove if count hits 0
  void removeFromCart(String productId) {
    if (cartItems.containsKey(productId)) {
      int currentQty = (cartItems[productId]!['quantity'] as num).toInt();
      if (currentQty > 1) {
        cartItems[productId]!['quantity'] = currentQty - 1;
      } else {
        cartItems.remove(productId);
      }
      cartItems.refresh();
    }
  }

  // Delete line item
  void deleteRow(String productId) {
    cartItems.remove(productId);
    cartItems.refresh();
  }

  // Subtotal calculation safely casting numbers
  double get totalAmount {
    double total = 0.0;
    cartItems.forEach((key, item) {
      double price = (item['price'] as num?)?.toDouble() ?? 0.0;
      int quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      total += (price * quantity);
    });
    return total;
  }

  // Total item count safely returning a plain int
  int get totalItemCount {
    int count = 0;
    cartItems.forEach((key, item) {
      count += (item['quantity'] as num?)?.toInt() ?? 0;
    });
    return count;
  }

  void clearCart() {
    cartItems.clear();
  }

  void incrementQuantity(String productId) {
    if (cartItems.containsKey(productId)) {
      int currentQty = (cartItems[productId]!['quantity'] as num).toInt();
      int stockBalance =
          (cartItems[productId]!['max_balance'] as num?)?.toInt() ?? 999;

      if (currentQty >= stockBalance) {
        Get.snackbar(
          "Limit Reached",
          "Cannot add more than available stock!",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      cartItems[productId]!['quantity'] = currentQty + 1;
      cartItems.refresh();
    }
  }

  void decrementQuantity(String productId) {
    removeFromCart(productId);
  }
}
