// lib/pages/sales_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:own/models/firestore.dart';

import 'package:own/pages/sale.dart';

class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesOrderPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by customer or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _searchQuery.isEmpty
                  ? _firestoreService.getAllSalesOrders()
                  : _firestoreService.searchSalesOrders(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final salesOrders = snapshot.data ?? [];

                if (salesOrders.isEmpty) {
                  return const Center(
                    child: Text(
                      'No sales orders found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: salesOrders.length,
                  itemBuilder: (context, index) {
                    final order = salesOrders[index];
                    return _buildSalesOrderCard(order, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesOrderCard(
    Map<String, dynamic> order,
    BuildContext context,
  ) {
    final status = order['status']?.toString() ?? 'Pending';
    final amount = (order['amount'] ?? 0).toString();
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final createdAt = order['createdAt'] as Timestamp?;
    final customerName =
        order['customerName']?.toString() ?? 'Unknown Customer';

    Color getStatusColor(String status) {
      switch (status) {
        case 'Pending':
          return Colors.orange;
        case 'Sent':
          return Colors.blue;
        case 'CashCollect':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return Center(
      child: SizedBox(
        width: 400,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['id']?.substring(0, 8) ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Chip(
                      label: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: getStatusColor(status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  customerName,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Phone: ${order['phone'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Items: ${items.length}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Amount: \$$amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    'Created: ${(createdAt.toDate())}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editOrder(order, context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteOrder(order['id'], context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editOrder(Map<String, dynamic> order, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditSalesOrderDialog(
        order: order,
        onOrderUpdated: () {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order updated successfully!')),
          );
        },
      ),
    );
  }

  void _deleteOrder(String? orderId, BuildContext context) {
    if (orderId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteSalesOrder(orderId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order deleted successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting order: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.order['customerName']?.toString() ?? '';
    _addressController.text = widget.order['address']?.toString() ?? '';
    _phoneController.text = widget.order['phone']?.toString() ?? '';
    _amountController.text = (widget.order['amount'] ?? 0).toString();
    _selectedStatus = widget.order['status']?.toString() ?? 'Pending';
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
