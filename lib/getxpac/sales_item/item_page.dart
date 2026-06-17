import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/getxpac/sales_item/item_edit.dart';
import 'package:own/getxpac/sales_item/stock_add_remove.dart';
import 'package:own/getxpac/sales_item/one_item_page.dart';
import 'package:own/utils/loading.dart';

class StockListPage extends StatelessWidget {
  const StockListPage({super.key});

  // 🟢 அලුත් Item එකක් ඇතුළත් කරන Popup Dialog එක
  void _showAddItemDialog(
    BuildContext context,
    StockListController controller,
  ) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.playlist_add, color: Colors.blue),
            SizedBox(width: 10),
            Text(
              "Add New Product",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter item name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (Rs.)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => double.tryParse(v ?? '') == null
                    ? "Enter a valid price"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Initial Stock Qty",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => int.tryParse(v ?? '') == null
                    ? "Enter a valid stock quantity"
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Get.back();
                await controller.addItem(
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text.trim()),
                  initialStock: int.parse(stockController.text.trim()),
                );
              }
            },
            child: const Text("Add Item"),
          ),
        ],
      ),
    );
  }

  // 🔴 Item එකක් Delete කරන්න කලින් අහන Confirmation Dialog එක
  void _showRemoveItemConfirm(
    BuildContext context,
    StockListController controller,
    String productId,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Product?"),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently remove '$itemName' from inventory? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.removeItem(productId);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StockListController controller = Get.put(StockListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Management"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, size: 28),
            onPressed: () => _showAddItemDialog(context, controller),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 🌟 FIX: Column එකක් දාලා Search Field එකයි ලිස්ට් එකයි වෙන් කලා
      body: Column(
        children: [
          // 🔍 Search Box UI එක
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (value) =>
                  controller.searchProducts(value), // ටයිප් කරද්දීම සර්ච් වෙනවා
              decoration: InputDecoration(
                hintText: "Search stock items by name or ID...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // 📦 Stock List එක Obx එකක් ඇතුලේ
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CustomLoading());
              }

              if (controller.products.isEmpty) {
                return const Center(
                  child: Text(
                    "No products found in inventory.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.products.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final product = controller.products[index];

                  final String productId = product['id'] ?? '';
                  final String itemName =
                      product['item_name'] ?? 'Unknown Item';
                  final int balance = product['balance'] ?? 0;
                  final double price = (product['price'] ?? 0).toDouble();
                  final bool isOutOfStock = balance <= 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: CircleAvatar(
                        backgroundColor: isOutOfStock
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: isOutOfStock
                              ? Colors.red
                              : Colors.blue.shade700,
                        ),
                      ),
                      title: Text(
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Price: LKR ${price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "ID: $productId",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Column(
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: const Icon(
                                      Icons.history,
                                      size: 18,
                                      color: Colors.blueGrey,
                                    ),
                                    label: const Text(
                                      "History",
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onPressed: () => Get.to(
                                      () => StockHistoryPage(
                                        productId: productId,
                                        itemName: itemName,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    label: const Text(
                                      "Edit Item",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onPressed: () {
                                      Get.to(
                                        () => StockEditPage(product: product),
                                      );
                                    },
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      "Remove Item",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onPressed: () => _showRemoveItemConfirm(
                                      context,
                                      controller,
                                      productId,
                                      itemName,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text(
                                        "Stock In",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              StockActionDialog(
                                                product: product,
                                                type: 'in',
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.remove, size: 18),
                                      label: const Text(
                                        "Stock Out",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: isOutOfStock
                                          ? null
                                          : () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    StockActionDialog(
                                                      product: product,
                                                      type: 'out',
                                                    ),
                                              );
                                            },
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}
