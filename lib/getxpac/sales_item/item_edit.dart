import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';

class StockEditPage extends StatefulWidget {
  final Map<String, dynamic> product; // Edit කරන්න ඕනෙ කරන item එකේ data ටික

  const StockEditPage({super.key, required this.product});

  @override
  State<StockEditPage> createState() => _StockEditPageState();
}

class _StockEditPageState extends State<StockEditPage> {
  final StockListController controller = Get.find<StockListController>();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController balanceController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController imageController;
  bool isActive = true;
  @override
  void initState() {
    super.initState();
    // දැනට තියෙන දත්ත ටික පටන් ගද්දිම TextFields වලට දානවා
    nameController = TextEditingController(text: widget.product['item_name']);
    priceController = TextEditingController(
      text: widget.product['price'].toString(),
    );
    balanceController = TextEditingController(
      text: widget.product['balance'].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );

    categoryController = TextEditingController(
      text: widget.product['category'] ?? '',
    );

    imageController = TextEditingController(
      text: (widget.product['images'] ?? []).isNotEmpty
          ? widget.product['images'][0]
          : '',
    );

    isActive = widget.product['isActive'] ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    balanceController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Stock Item"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              // 1. Item Name Field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_rounded),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter item name" : null,
              ),
              const SizedBox(height: 16),

              // 2. Price Field
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Price (LKR)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Please enter price";
                  if (double.tryParse(value) == null) {
                    return "Enter a valid price";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Balance / Stock Field
              TextFormField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Current Stock Balance",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Please enter stock balance";
                  if (int.tryParse(value) == null) {
                    return "Enter a valid integer";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL",
                  border: OutlineInputBorder(),
                ),
              ),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              await controller.editStockItem(
                                productId: widget.product['id'],
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: categoryController.text.trim(),
                                price: double.parse(priceController.text),
                                balance: int.parse(balanceController.text),
                                images: [imageController.text.trim()],
                                isActive: isActive,
                              );
                            }
                            Get.back(); // Update වුනාට පස්සේ කලින් පිටුවට යනවා
                          },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "UPDATE STOCK ITEM",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
