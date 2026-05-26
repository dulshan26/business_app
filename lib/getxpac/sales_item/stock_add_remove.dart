import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';

class StockActionDialog extends StatelessWidget {
  final Map<String, dynamic> product;
  final String type; // "in" හෝ "out"

  const StockActionDialog({
    super.key,
    required this.product,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final StockListController controller = Get.find<StockListController>();
    final TextEditingController qtyController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool isIn = type == 'in';
    final Color themeColor = isIn ? Colors.green.shade700 : Colors.red.shade700;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: themeColor,
          ),
          const SizedBox(width: 10),
          Text(
            isIn ? "Stock In (Restock)" : "Stock Out (Sale)",
            style: TextStyle(color: themeColor, fontSize: 18),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Item: ${product['item_name']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Current Stock: ${product['balance'] ?? 0}",
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 24),

              // Qty Input Field
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter quantity";
                  final int? qty = int.tryParse(value);
                  if (qty == null || qty <= 0) return "Enter a valid number";
                  if (!isIn && qty > (product['balance'] ?? 0)) {
                    return "Not enough stock available!";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Note Input Field
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: "Note / Description (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              // Dialog එක වහනවා
              Get.back();

              // Database එක Update කරන්න Controller එකට දත්ත යවනවා
              await controller.updateStock(
                productId: product['id'],
                itemName: product['item_name'],
                quantity: int.parse(qtyController.text),
                currentBalance: product['balance'] ?? 0,
                type: type,
                note: noteController.text,
              );
            }
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
