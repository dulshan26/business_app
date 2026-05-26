import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class SalesEntryPage extends StatelessWidget {
  final String customerPhone;
  final String? customerName; // 🛠️ String? (Nullable)
  final String? customerAddress; // 🛠️ String? (Nullable)
  final String? customerPhone2;
  // Constructor eka clean kala putha
  SalesEntryPage({
    super.key,
    required this.customerPhone,
    this.customerName,
    this.customerAddress,
    this.customerPhone2,
  });

  // Controller eka connect karagannawa
  final controller = Get.put(SalesController());
  final noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Items"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(25),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "Customer: $customerPhone",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Box (Type කරද්දීම list එක වෙනස් වෙනවා)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => controller.searchStock(value),
              decoration: const InputDecoration(
                hintText: "Search stock items...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 📦 Stock List (Firebase එකෙන් එන බඩු ටික)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Available Stock",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredStockItems.isEmpty) {
                return const Center(child: Text("No items found in Stock"));
              }
              return ListView.builder(
                itemCount: controller.filteredStockItems.length,
                itemBuilder: (context, index) {
                  final stock = controller.filteredStockItems[index];
                  return ListTile(
                    title: Text(stock['item_name']),
                    subtitle: Text(
                      "Price: LKR ${stock['price']} | Stock: ${stock['balance']}",
                    ),
                    trailing: const Icon(Icons.add_circle, color: Colors.green),
                    onTap: () => controller.addItemToCart(
                      stock,
                    ), // Click කලාම Cart එකට යනවා
                  );
                },
              );
            }),
          ),

          const Divider(thickness: 2, color: Colors.blueGrey),

          // 🛒 Cart UI (තෝරාගත් බඩු ලැයිස්තුව)
          const Text(
            "🛒 Current Order Cart",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          Expanded(
            flex: 2,
            child: Obx(() {
              if (controller.selectedItems.isEmpty) {
                return const Center(
                  child: Text("Cart is Empty. Tap items above to add."),
                );
              }
              return ListView.builder(
                itemCount: controller.selectedItems.length,
                itemBuilder: (context, index) {
                  final cartItem = controller.selectedItems[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      cartItem['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "LKR ${cartItem['price']} x ${cartItem['quantity']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => controller.decreaseQty(index),
                        ),
                        Text(
                          "${cartItem['quantity']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () => controller.increaseQty(index),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          // 💰 Summary & Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
                    SizedBox(
                      width: 150, // කොටුවේ පළල
                      child: TextField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        decoration: const InputDecoration(
                          border:
                              OutlineInputBorder(), // කොටුවක් වගේ පේන්න බෝඩර් එකක් දැම්මා
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          isDense: true,
                          prefixText: "LKR ",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.saveSalesTransaction(
                              phone: customerPhone,
                              name: customerName,
                              address: customerAddress,
                              phone2: customerPhone2,
                            ),
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "COMPLETE & SAVE SALE",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
