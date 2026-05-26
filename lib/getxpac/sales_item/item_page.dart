import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/getxpac/sales_item/stock_add_remove.dart';
import 'package:own/getxpac/sales_item/one_item_page.dart';

class StockListPage extends StatelessWidget {
  const StockListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller එක සාදා පිටුවට සම්බන්ධ කිරීම
    final StockListController controller = Get.put(StockListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Management"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        // දත්ත Load වන විට පෙන්වන Loading Screen එක
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Database එකේ කිසිම බඩුවක් නැත්නම් පෙන්වන පිටුව
        if (controller.products.isEmpty) {
          return const Center(
            child: Text(
              "No products found in inventory.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        // බඩු ලැයිස්තුව ලස්සනට බලාගන්නා කොටස
        return ListView.builder(
          itemCount: controller.products.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final product = controller.products[index];

            // ආරක්ෂිතව Field අගයන් ලබාගැනීම (Null safety සඳහා)
            final String productId = product['id'] ?? '';
            final String itemName = product['item_name'] ?? 'Unknown Item';
            final int balance = product['balance'] ?? 0;

            // Stock එක ඉවරද නැද්ද යන්න මත UI එක හැඩගැන්වීම
            final bool isOutOfStock = balance <= 0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
              child: ExpansionTile(
                // ListTile එක වෙනුවට ExpansionTile එකක් දැම්මාම බටන්ස් ලස්සනට හැංගිලා තියෙයි
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape:
                    const Border(), // ExpansionTile එක Expand වුනහම උඩින් සහ පල්ලෙහායින් එන ඉරි ඉවත් කිරීමට
                collapsedShape: const Border(),

                // වම්පස ඇති අයිකනය
                leading: CircleAvatar(
                  backgroundColor: isOutOfStock
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: isOutOfStock ? Colors.red : Colors.blue.shade700,
                  ),
                ),

                // මැද ප්‍රධාන මාතෘකාව (Item Name)
                title: Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                // උප මාතෘකාව (Document ID එක ලාවට පෙන්වීමට - Debugging වලට ලේසියි)
                subtitle: Text(
                  "ID: $productId",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),

                // දකුණු පසින් පෙනෙන Stock Count (Balance) එක
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOutOfStock ? "Out of Stock" : "Qty: $balance",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isOutOfStock
                          ? Colors.red.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                ),

                // 🔽 Card එක උඩ Click කරාම පල්ලෙහායින් මතුවන Buttons ටික
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 📜 History Button
                        TextButton.icon(
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text("History"),
                          onPressed: () => Get.to(
                            () => StockHistoryPage(
                              productId: productId,
                              itemName: itemName,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // 🟢 Stock In Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Stock In"),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => StockActionDialog(
                                product: product,
                                type: 'in',
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // 🔴 Stock Out Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.remove, size: 18),
                          label: const Text("Stock Out"),
                          onPressed: isOutOfStock
                              ? null // Stock 0 නම් බටන් එක disable වේ
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => StockActionDialog(
                                      product: product,
                                      type: 'out',
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
