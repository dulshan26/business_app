import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/getxpac/sales_item/item_edit.dart';
import 'package:own/getxpac/sales_item/item_model.dart';
import 'package:own/getxpac/sales_item/stock_add_remove.dart';
import 'package:own/getxpac/sales_item/one_item_page.dart';
import 'package:own/utils/loading.dart';

class StockListPage extends StatelessWidget {
  const StockListPage({super.key});

  // 🟢 அලුත් Item එකක් ඇතුළත් කරන Popup Dialog එක
  void _showImagePreview(
    BuildContext context,
    String imageUrl,
    String itemName,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: 250,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 50,
              child: Text(
                itemName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
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
            onPressed: () => Get.to(() => const StockEditPage()),
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
                  final item = ItemModel.fromMap(product, id: productId);

                  // 🌟 0 වෙනි පින්තූරය (Image 0) ආරක්ෂිතව වෙන් කරගන්නා ආකාරය
                  String? imageUrl;
                  if (product['images'] != null &&
                      product['images'] is List &&
                      (product['images'] as List).isNotEmpty) {
                    // ලිස්ට් එකේ තියෙන 0 වෙනි element එක (First Image) String එකක් විදිහට ගන්නවා
                    imageUrl = product['images'][0]?.toString();
                  }

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
                      leading: GestureDetector(
                        onTap: (imageUrl != null && imageUrl.isNotEmpty)
                            ? () => _showImagePreview(
                                context,
                                imageUrl!,
                                itemName,
                              )
                            : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOutOfStock
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child:
                                imageUrl != null &&
                                    imageUrl.isNotEmpty &&
                                    imageUrl.startsWith('http')
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      isOutOfStock
                                                          ? Colors.red
                                                          : Colors.blue,
                                                    ),
                                              ),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.broken_image_outlined,
                                        color: isOutOfStock
                                            ? Colors.red
                                            : Colors.blue.shade700,
                                        size: 22,
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.inventory_2_outlined,
                                    color: isOutOfStock
                                        ? Colors.red
                                        : Colors.blue.shade700,
                                    size: 22,
                                  ),
                          ),
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
                              if (item.hasVariants)
                                _buildVariantStockRows(item),
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

  Widget _buildVariantStockRows(ItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Option variants',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(flex: 5, child: Text('Option / Variant')),
              Expanded(
                flex: 2,
                child: Text('Stock', textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 3,
                child: Text('Price', textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        ...item.options.expand(
          (option) => option.variants.map(
            (variant) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      '${option.name}: ${variant.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${variant.stock}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: variant.stock > 0
                            ? Colors.blueGrey.shade800
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'LKR ${(variant.price ?? item.price).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
