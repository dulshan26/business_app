import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/sub_page/cart_page.dart';
// import 'package:own/ecommerce/page/sub_page/checkout_page.dart'; // ඔයාගේ CheckoutView එක තියෙන නිවැරදි path එක දාන්න

class CartView extends StatelessWidget {
  final CartController cartController = Get.find<CartController>();

  CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        // 🛒 Cart එක හිස් නම් හිස් පිටුවක් පෙන්වනවා
        if (cartController.cartItems.isEmpty) {
          return const Center(
            child: Text("Your cart is empty!", style: TextStyle(fontSize: 18)),
          );
        }

        // Map එකෙන් List එකක් හදාගන්නවා UI එකට දාන්න
        final items = cartController.cartItems.values.toList();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  // 🌟 OneItemPage එකේ logic එකටම productId එක safe විදිහට ගන්නවා
                  final String productId =
                      (item['id'] ?? item['item_name'] ?? index).toString();

                  // Image key එක null හෝ empty ද කියලා check කරනවා
                  final String imageUrl =
                      (item['main_image'] ?? item['image'] ?? '').toString();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading:
                          imageUrl.isNotEmpty && imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(
                        item['item_name'] ?? 'Unknown Item',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "LKR ${(item['price'] ?? 0).toStringAsFixed(2)} x ${item['quantity'] ?? 1}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ➖ Quantity අඩු කරන Button එක
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              // 🌟 clean decrement call
                              cartController.decrementQuantity(productId);
                            },
                          ),
                          Text(
                            "${item['quantity'] ?? 1}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // ➕ Quantity වැඩි කරන Button එක
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              cartController.incrementQuantity(productId);
                            },
                          ),
                          // 🗑️ Row එකම Delete කරන Button එක
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () =>
                                cartController.deleteRow(productId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 💰 Bottom Summary Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "LKR ${cartController.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF25D366,
                        ), // WhatsApp Green Color
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.to(() => CheckoutView());
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Order via WhatsApp",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
