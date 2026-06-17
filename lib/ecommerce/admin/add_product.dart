import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:own/ecommerce/controller/product_controller.dart';
import 'package:own/ecommerce/models/product_model.dart';

class AddProductPage extends StatelessWidget {
  const AddProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductController());
    final nameController = TextEditingController();

    final priceController = TextEditingController();

    final descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                controller.addProduct(
                  ProductModel(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0,
                    description: descriptionController.text,
                    images: ["https://via.placeholder.com/150"],
                    category: '',
                    stock: 0,
                    isActive: true,
                    createdAt: DateTime.now(), // Placeholder image
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Add Product"),
            ),
          ],
        ),
      ),
    );
  }
}
