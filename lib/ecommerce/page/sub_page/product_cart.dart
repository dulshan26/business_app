import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/models/cart_model.dart';

class ProductCard extends StatelessWidget {
  final CartItem product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Inject or find the GetX CartController
    final CartController cartController = Get.put(CartController());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rs. ${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                  onPressed: () {
                    // Convert your CartItem model data to pass safely into the Controller Map
                    cartController.addToCart({
                      'id': product.id,
                      'item_name': product.name,
                      'price': product.price,
                      'main_image': product.imageUrl,
                      'balance':
                          10, // Default fallback if stock limit isn't explicitly passed
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
