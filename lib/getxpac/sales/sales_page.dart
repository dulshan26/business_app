import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales/sales_model.dart';
import 'package:own/getxpac/sales_item/item_model.dart';
import 'package:own/utils/loading.dart';

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

  Future<void> _selectItem(
    BuildContext context,
    Map<String, dynamic> stock,
  ) async {
    final item = ItemModel.fromMap(stock, id: stock['id'].toString());
    if (!item.hasVariants) {
      final availableStock = int.tryParse(stock['balance'].toString()) ?? 0;
      if (availableStock <= 0) {
        Get.snackbar('Out of stock', 'This item is currently unavailable.');
        return;
      }
      controller.addItemToCart(
        stock,
        unitPrice: item.price,
        availableStock: availableStock,
      );
      return;
    }

    final selection = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SalesVariantPickerDialog(item: item),
    );
    if (selection == null) return;
    controller.addItemToCart(
      stock,
      optionName: selection['optionName'] as String,
      variantName: selection['variantName'] as String,
      unitPrice: selection['price'] as double,
      availableStock: selection['stock'] as int,
    );
  }

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
                return const Center(child: CustomLoading());
              }
              if (controller.filteredStockItems.isEmpty) {
                return const Center(child: Text("No items found in Stock"));
              }
              return ListView.builder(
                itemCount: controller.filteredStockItems.length,
                itemBuilder: (context, index) {
                  final stock = controller.filteredStockItems[index];
                  final item = ItemModel.fromMap(stock);
                  final hasVariants = item.hasVariants;
                  return ListTile(
                    title: Text(stock['item_name']),
                    subtitle: Text(
                      hasVariants
                          ? "From LKR ${item.startingPrice ?? item.price} | ${item.options.length} option(s)"
                          : "Price: LKR ${stock['price']} | Stock: ${stock['balance']}",
                    ),
                    trailing: const Icon(Icons.add_circle, color: Colors.green),
                    onTap: () => _selectItem(context, stock),
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
                      cartItem['variantName'] == null
                          ? cartItem['name']
                          : "${cartItem['name']} • ${cartItem['optionName']}: ${cartItem['variantName']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "LKR ${cartItem['price']} × ${cartItem['quantity']} • Stock: ${cartItem['availableStock']}",
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

class _SalesVariantPickerDialog extends StatefulWidget {
  final ItemModel item;

  const _SalesVariantPickerDialog({required this.item});

  @override
  State<_SalesVariantPickerDialog> createState() =>
      _SalesVariantPickerDialogState();
}

class _SalesVariantPickerDialogState extends State<_SalesVariantPickerDialog> {
  String? _optionName;
  String? _variantName;

  StockOptionModel? get _selectedOption {
    for (final option in widget.item.options) {
      if (option.name == _optionName) return option;
    }
    return null;
  }

  ProductOptionVariantModel? get _selectedVariant {
    for (final variant
        in _selectedOption?.variants ?? const <ProductOptionVariantModel>[]) {
      if (variant.name == _variantName) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedVariant = _selectedVariant;
    return AlertDialog(
      title: Text('Choose ${widget.item.name} option'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _optionName,
            decoration: const InputDecoration(
              labelText: 'Option',
              border: OutlineInputBorder(),
            ),
            items: widget.item.options
                .where((option) => option.variants.isNotEmpty)
                .map(
                  (option) => DropdownMenuItem(
                    value: option.name,
                    child: Text(option.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _optionName = value;
                _variantName = null;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_optionName),
            initialValue: _variantName,
            decoration: const InputDecoration(
              labelText: 'Variant',
              border: OutlineInputBorder(),
            ),
            items: _selectedOption?.variants
                .map(
                  (variant) => DropdownMenuItem(
                    value: variant.name,
                    enabled: variant.stock > 0,
                    child: Text(
                      '${variant.name} • ${variant.stock} in stock • LKR ${(variant.price ?? widget.item.price).toStringAsFixed(2)}',
                    ),
                  ),
                )
                .toList(),
            onChanged: _selectedOption == null
                ? null
                : (value) {
                    setState(() {
                      _variantName = value;
                    });
                  },
          ),
          if (selectedVariant != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Unit price: LKR ${(selectedVariant.price ?? widget.item.price).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: selectedVariant == null || selectedVariant.stock <= 0
              ? null
              : () => Navigator.of(context).pop({
                  'optionName': _optionName!,
                  'variantName': selectedVariant.name,
                  'price': selectedVariant.price ?? widget.item.price,
                  'stock': selectedVariant.stock,
                }),
          child: const Text('Add item'),
        ),
      ],
    );
  }
}
