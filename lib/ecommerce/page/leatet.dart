import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';

class LatestProducts extends StatelessWidget {
  const LatestProducts({super.key});

  @override
  Widget build(BuildContext context) {
    final StockListController controller = Get.put(StockListController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: controller.products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (_, index) {
          final product = controller.products[index];

          return Card(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.inventory_2, size: 50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        product['item_name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 5),

                      Text("Rs. ${product['price'] ?? 0}"),

                      Text("Stock: ${product['balance'] ?? 0}"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
