import 'package:flutter/material.dart';
import 'package:own/firebase/firestore.dart';

void showDeliveryPopup(BuildContext context, Map<String, dynamic> order) {
  final trackingController = TextEditingController(
    text: order['trackingNumber'] ?? '',
  );
  final postageController = TextEditingController(
    text: order['postageCost']?.toString() ?? '',
  );
  String status = order['status'] ?? 'Pending';
  String? courier = order['courierPartner'];

  final FirestoreService firestoreService = FirestoreService();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Update Delivery Info'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Order Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'Sent', child: Text('Sent')),
                      DropdownMenuItem(
                        value: 'CashCollect',
                        child: Text('Cash Collect'),
                      ),
                      DropdownMenuItem(value: 'Cancel', child: Text('Cancel')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() => status = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: trackingController,
                    decoration: const InputDecoration(
                      labelText: 'Tracking Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: courier,
                    decoration: const InputDecoration(
                      labelText: 'Courier Partner',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Royal Courier',
                        child: Text('Royal Courier'),
                      ),
                      DropdownMenuItem(
                        value: 'SL Post',
                        child: Text('SL Post'),
                      ),
                    ],
                    onChanged: (value) {
                      setStateDialog(() => courier = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: postageController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Postage Cost',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await firestoreService.updateSalesOrder(order['id'], {
                      'status': status,
                      'trackingNumber': trackingController.text.trim(),
                      'courierPartner': courier,
                      'postageCost':
                          double.tryParse(postageController.text) ?? 0.0,
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Delivery details updated successfully!',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating: $e')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
