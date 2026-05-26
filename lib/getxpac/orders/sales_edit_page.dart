import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class SalesEditPage extends StatefulWidget {
  final SalesModel sales;
  const SalesEditPage({super.key, required this.sales});

  @override
  State<SalesEditPage> createState() => _SalesEditPageState();
}

class _SalesEditPageState extends State<SalesEditPage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController phone2Controller;
  late TextEditingController addressController;
  late TextEditingController totalAmountController;
  late TextEditingController noteController;
  late TextEditingController courierStatusController;
  late TextEditingController trackingNumberController;
  List<Map<String, dynamic>> editedItems = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.sales.customerName);
    phoneController = TextEditingController(text: widget.sales.customerPhone);
    phone2Controller = TextEditingController(text: widget.sales.custonerPhone2);
    addressController = TextEditingController(
      text: widget.sales.customerAddress,
    );
    totalAmountController = TextEditingController(
      text: widget.sales.totalAmount.toString(),
    );
    noteController = TextEditingController(text: widget.sales.note);
    courierStatusController = TextEditingController(
      text: widget.sales.courierStatus,
    );
    trackingNumberController = TextEditingController(
      text: widget.sales.trackingNumber,
    );
    editedItems = List.from(widget.sales.items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Customer Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone 1"),
            ),
            TextField(
              controller: phone2Controller,
              decoration: const InputDecoration(labelText: "Phone 2"),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            TextField(
              controller: totalAmountController,
              decoration: const InputDecoration(labelText: "Total Amount"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),
            TextField(
              controller: courierStatusController,
              decoration: const InputDecoration(labelText: "Courier Status"),
            ),
            TextField(
              controller: trackingNumberController,
              decoration: const InputDecoration(labelText: "Tracking Number"),
            ),
            const SizedBox(height: 20),
            // TextField වලට පස්සේ මේ කොටස දාන්න
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  onPressed: _addNewItem, // අලුත් Item එකක් Add කරන්න
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: editedItems.length,
              itemBuilder: (context, index) {
                final item = editedItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item['name'] ?? "Unknown"),
                    subtitle: Text(
                      "Price: ${item['price']} | Qty: ${item['quantity']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          editedItems.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // දත්ත යාවත්කාලීන කිරීම
                Map<String, dynamic> updatedData = {
                  'customerName': nameController.text,
                  'customerPhone': phoneController.text,
                  'custonerPhone2': phone2Controller.text,
                  'customerAddress': addressController.text,
                  'totalAmount':
                      double.tryParse(totalAmountController.text) ?? 0.0,
                  'note': noteController.text,
                  'courierStatus': courierStatusController.text,
                  'items': editedItems,
                  'trackingNumber': trackingNumberController.text,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                await FirestoreService().updateSalesOrder(
                  widget.sales.id!,
                  updatedData,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Order updated successfully!"),
                    ),
                  );
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Controller Dispose කිරීම අනිවාර්යයි
    nameController.dispose();
    phoneController.dispose();
    phone2Controller.dispose();
    addressController.dispose();
    totalAmountController.dispose();
    noteController.dispose();
    courierStatusController.dispose();
    trackingNumberController.dispose();
    for (var controller in editedItems.map((item) => item['controller'])) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    // SalesController එකේ තියෙන Items ටික ගමු
    final SalesController salesController = Get.find<SalesController>();

    // තාවකාලික තෝරාගැනීම සඳහා variable එකක්

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Item from Stock"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: salesController.allStockItems.length,
            itemBuilder: (context, index) {
              final item = salesController.allStockItems[index];
              return ListTile(
                title: Text(item['item_name']),
                subtitle: Text("Price: ${item['price']}"),
                onTap: () {
                  setState(() {
                    editedItems.add({
                      'name': item['item_name'],
                      'price': item['price'],
                      'quantity': 1,
                    });
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
