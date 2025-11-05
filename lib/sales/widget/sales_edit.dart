import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:own/firebase/firestore.dart';

class EditSalesOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderUpdated;

  const EditSalesOrderDialog({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<EditSalesOrderDialog> createState() => _EditSalesOrderDialogState();
}

class _EditSalesOrderDialogState extends State<EditSalesOrderDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedStatus;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.order['customerName']?.toString() ?? '';
    _addressController.text = widget.order['address']?.toString() ?? '';
    _phoneController.text = widget.order['phone']?.toString() ?? '';
    _amountController.text = (widget.order['amount'] ?? 0).toString();
    _selectedStatus = widget.order['status']?.toString() ?? 'Pending';
    _items = List<Map<String, dynamic>>.from(widget.order['items'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['Pending', 'Sent', 'CashCollect'].map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              children: _items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item['name'] ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                        ),
                        onChanged: (val) => _items[index]['name'] = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: item['quantity']?.toString() ?? '1',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        onChanged: (val) =>
                            _items[index]['quantity'] = int.tryParse(val) ?? 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(index);
                        });
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _items.add({'name': '', 'quantity': 1});
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Item"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _updateOrder, child: const Text('Update')),
      ],
    );
  }

  Future<void> _updateOrder() async {
    try {
      final updates = {
        'customerName': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'status': _selectedStatus,
        'items': _items,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.updateSalesOrder(widget.order['id'], updates);
      widget.onOrderUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
