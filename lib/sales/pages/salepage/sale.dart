// lib/pages/sale.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _trackingController = TextEditingController();
  final _postageController = TextEditingController();
  String? _selectedCurier;

  final _firestore = FirebaseFirestore.instance;

  final List<SelectedItem> _selectedItems = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _trackingController.dispose();
    _postageController.dispose();
    super.dispose();
  }

  StockItem _stockFromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StockItem(
      docId: doc.id,
      itemId: d['item_id'] is int
          ? d['item_id']
          : int.tryParse('${d['item_id']}') ?? 0,
      name: d['item_name'] ?? '',
      description: d['description'] ?? '',
      balance: d['balance'] is int
          ? d['balance']
          : (d['balance']?.toInt() ?? 0),
    );
  }

  Future<List<StockItem>> fetchStockItems() async {
    final snap = await _firestore.collection('stock').orderBy('item_id').get();
    return snap.docs.map((d) => _stockFromDoc(d)).toList();
  }

  void showAddItemDialog() async {
    final allItems = await fetchStockItems();
    if (!mounted) return;

    List<StockItem> available = allItems
        .where((s) => !_selectedItems.any((sel) => sel.itemId == s.itemId))
        .toList();

    TextEditingController searchController = TextEditingController();
    List<StockItem> filtered = List.from(available);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Select Item',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 430,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search item',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filtered = available
                            .where(
                              (it) => it.name.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = filtered[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text('${s.itemId}'),
                                ),
                                title: Text(s.name),
                                subtitle: Text(s.description),
                                trailing: Text('Stock: ${s.balance}'),
                                onTap: () {
                                  _addSelectedItem(s);
                                  Navigator.pop(context);
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
      ),
    );
  }

  void _addSelectedItem(StockItem stock) {
    setState(() {
      _selectedItems.add(
        SelectedItem(
          docId: stock.docId,
          itemId: stock.itemId,
          name: stock.name,
          quantity: 1,
        ),
      );
    });
  }

  void _increaseQty(int idx) {
    setState(() => _selectedItems[idx].quantity++);
  }

  void _decreaseQty(int idx) {
    setState(() {
      if (_selectedItems[idx].quantity > 1) {
        _selectedItems[idx].quantity--;
      } else {
        _selectedItems.removeAt(idx);
      }
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final itemsAsMaps = _selectedItems
          .map((s) => {'id': s.itemId, 'name': s.name, 'quantity': s.quantity})
          .toList();

      final orderData = {
        'customerName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
        'items': itemsAsMaps,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'trackingNumber': "",
        'postageCost': double.tryParse(_postageController.text.trim()) ?? 0.0,
        'curier': _selectedCurier ?? 'Not Selected',
        'smsSent': 'no',
      };

      await _firestore.collection('sales').add(orderData);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order saved')));

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _selectedItemTile(SelectedItem item, int index) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('ID: ${item.itemId}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _decreaseQty(index),
            ),
            Text(
              item.quantity.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: () => _increaseQty(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Sales Order'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionTitle('Customer Details'),
              const SizedBox(height: 12),

              _inputBox(
                _nameController,
                'Customer Name',
                validator: 'Enter name',
              ),
              _gap(),
              _inputBox(
                _phoneController,
                'Phone Number',
                keyboard: TextInputType.phone,
                validator: 'Enter phone',
              ),
              _gap(),
              _inputBox(_addressController, 'Address'),
              _gap(),
              _inputBox(
                _amountController,
                'Total Amount',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 20),
              _sectionTitle('Items'),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ),

              const SizedBox(height: 12),

              _selectedItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No items added yet.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedItems.length,
                      itemBuilder: (c, i) =>
                          _selectedItemTile(_selectedItems[i], i),
                    ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _sectionTitle(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _inputBox(
    TextEditingController controller,
    String label, {
    String? validator,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboard,
      validator: validator != null
          ? (v) => v == null || v.trim().isEmpty ? validator : null
          : null,
    );
  }

  Widget _gap() => const SizedBox(height: 12);
}

class StockItem {
  final String docId;
  final int itemId;
  final String name;
  final String description;
  final int balance;

  StockItem({
    required this.docId,
    required this.itemId,
    required this.name,
    required this.description,
    required this.balance,
  });
}

class SelectedItem {
  final String docId;
  final int itemId;
  final String name;
  int quantity;

  SelectedItem({
    required this.docId,
    required this.itemId,
    required this.name,
    required this.quantity,
  });
}
