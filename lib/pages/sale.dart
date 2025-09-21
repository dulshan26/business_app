// lib/pages/sale.dart
import 'package:flutter/material.dart';
import 'package:own/models/firestore.dart';
import 'package:own/models/order_model.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String? selectedItem;

  void addItemToOrder() {
    if (selectedItem != null) {
      final item = itemList.firstWhere(
        (i) => i.name == selectedItem,
        orElse: () => ItemModel(id: "", name: ""),
      );
      if (item.id.isNotEmpty) {
        setState(() {
          orderItems.add(item);
        });
      }
    }
  }

  Future<void> saveOrder() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        phoneController.text.isEmpty ||
        amountController.text.isEmpty ||
        orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and add at least one item"),
        ),
      );
      return;
    }

    try {
      final salesData = {
        "customerName": nameController.text,
        "address": addressController.text,
        "phone": phoneController.text,
        "amount": double.tryParse(amountController.text) ?? 0.0,
        "status": "Pending",
        "items": orderItems.map((e) => {"id": e.id, "name": e.name}).toList(),
      };

      final orderId = await _firestoreService.createSalesOrder(salesData);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sales Order #$orderId Saved to Firebase!")),
      );

      // Clear form
      setState(() {
        nameController.clear();
        addressController.clear();
        phoneController.clear();
        amountController.clear();
        selectedItem = null;
        orderItems.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Order Page")),
      body: Center(
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Customer info fields
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Customer Name"),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone Number"),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: "Amount"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Item dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedItem,
                  decoration: const InputDecoration(labelText: "Select Item"),
                  items: itemList.map((item) {
                    return DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedItem = value;
                    });
                  },
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: addItemToOrder,
                  child: const Text("Add Item"),
                ),
                const SizedBox(height: 20),

                // Show added items
                if (orderItems.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Order Items:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...orderItems.map(
                        (item) => ListTile(
                          title: Text(item.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                orderItems.remove(item);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: saveOrder,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Order to Firebase"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
