// lib/pages/sale.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/sales/order_model.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers for customer details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _trackingController = TextEditingController();
  final _postageController = TextEditingController();

  String? _selectedCurier;

  // List to hold items added to the current order
  final List<ItemModel> _selectedItems = [];
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _trackingController.dispose();
    _postageController.dispose();

    super.dispose();
  }

  /// Shows a dialog to select an item from the global itemList
  void _showAddItemDialog() {
    final availableItems = itemList
        .where(
          (item) => !_selectedItems.any((selected) => selected.id == item.id),
        )
        .toList();

    TextEditingController searchController = TextEditingController();
    List<ItemModel> filteredItems = List.from(availableItems);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select an Item'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔍 Search Bar
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search item',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredItems = availableItems
                              .where(
                                (item) => item.name.toLowerCase().contains(
                                  value.toLowerCase(),
                                ),
                              )
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // 📦 Item List
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ListTile(
                            title: Text(item.name),
                            onTap: () {
                              _addItem(item);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Adds a new item to the order with a default quantity of 1
  void _addItem(ItemModel item) {
    setState(() {
      // Create a new instance with quantity 1
      _selectedItems.add(ItemModel(id: item.id, name: item.name, quantity: 1));
    });
  }

  /// Increments the quantity of an item at a given index
  void _incrementQuantity(int index) {
    setState(() {
      _selectedItems[index].quantity++;
    });
  }

  /// Decrements the quantity of an item, removing it if quantity becomes 0
  void _decrementQuantity(int index) {
    setState(() {
      if (_selectedItems[index].quantity > 1) {
        _selectedItems[index].quantity--;
      } else {
        // If quantity is 1, remove the item
        _selectedItems.removeAt(index);
      }
    });
  }

  /// Saves the complete order to Firestore
  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the order.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert list of ItemModel to a list of Maps for Firestore
      final itemsAsMaps = _selectedItems
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'quantity': item.quantity,
            },
          )
          .toList();

      // Create the order data map
      final orderData = {
        'customerName': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'items': itemsAsMaps,
        'status': 'Pending', // Default status
        'createdAt': FieldValue.serverTimestamp(),
        'trackingNumber': _trackingController.text,
        'postageCost': double.tryParse(_postageController.text) ?? 0.0,
        'curier': _selectedCurier ?? 'Not Selected',
      };

      // Call Firestore service to add the document
      await _firestoreService.createSalesOrder(orderData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order saved successfully!')),
      );
      Navigator.of(context).pop(); // Go back to the list page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save order: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Sales Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer details section
              const Text(
                'Customer Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an amount' : null,
              ),
              const SizedBox(height: 12),

              const Divider(height: 40),

              // Items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    onPressed: _showAddItemDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // List of selected items
              _selectedItems.isEmpty
                  ? const Center(child: Text('No items added yet.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedItems.length,
                      itemBuilder: (context, index) {
                        final item = _selectedItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _decrementQuantity(index),
                                ),
                                Text(
                                  item.quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _incrementQuantity(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 30),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
