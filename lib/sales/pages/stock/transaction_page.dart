import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Assuming 'package:own/sales/pages/stock/firebase_stock.dart' contains FirebaseStock
import 'package:own/sales/pages/stock/firebase_stock.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  String? _selectItemId;
  String _transactionType = 'in'; // 'in' or 'out'

  final firebaseStock = FirebaseStock();

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  // --- Widget for displaying a single transaction history item ---
  Widget _buildTransactionTile(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'in';
    final quantity = data['quantity'] ?? 0;
    final itemName = data['itemName'] ?? 'Unknown Item';
    final timestamp = data['timestamp'] as Timestamp?;

    final color = type == 'in' ? Colors.green.shade700 : Colors.red.shade700;
    final icon = type == 'in' ? Icons.arrow_upward : Icons.arrow_downward;
    final dateString = timestamp != null
        ? (timestamp.toDate()).toString().split('.')[0] // Format date simply
        : 'No date';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(dateString),
        trailing: Text(
          '${type == 'in' ? '+' : '-'}$quantity',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Transaction Page"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.goNamed('dashboard');
          },
        ),
      ),
      body: SingleChildScrollView(
        // Changed to SingleChildScrollView for content overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Record New Transaction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              /// --- TRANSACTION INPUT FORM ---
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// SELECT ITEM
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('stock')
                          .orderBy('item_name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final items = snapshot.data!.docs;

                        // Check if the currently selected item ID still exists
                        if (_selectItemId != null &&
                            !items.any((doc) => doc.id == _selectItemId)) {
                          // If the selected item was deleted, clear the selection
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() => _selectItemId = null);
                          });
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectItemId, // Added value property
                          decoration: const InputDecoration(
                            labelText: "Select Item",
                            border: OutlineInputBorder(),
                          ),
                          items: items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text("${data['item_name']}"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectItemId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select an item' : null,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Quantity
                    TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter quantity";
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return "Enter a valid positive quantity";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    /// IN / OUT Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Stock In'),
                          selected: _transactionType == 'in',
                          onSelected: (_) =>
                              setState(() => _transactionType = 'in'),
                        ),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Stock Out'),
                          selected: _transactionType == 'out',
                          onSelected: (_) =>
                              setState(() => _transactionType = 'out'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate() ||
                              _selectItemId == null) {
                            return;
                          }

                          // Parse quantity
                          final qty = int.parse(_qtyController.text);

                          // Get item name
                          final doc = await FirebaseFirestore.instance
                              .collection('stock')
                              .doc(_selectItemId!)
                              .get();

                          final name = doc['item_name'];

                          await firebaseStock.recordTransaction(
                            stockDocId: _selectItemId!,
                            itemName: name,
                            quantity: qty,
                            type: _transactionType,
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction recorded'),
                            ),
                          );

                          // Reset form fields
                          _qtyController.clear();
                          setState(() {
                            // Keep _selectItemId as is, but clear type to default 'in'
                            _transactionType = 'in';
                          });
                        },
                        child: const Text('Save Transaction'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// --- TRANSACTION HISTORY DISPLAY ---
              const Text(
                'Transaction History (Last 10)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stockTransaction')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading history: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final transactions = snapshot.data!.docs;

                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No transactions recorded yet."),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final doc = transactions[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildTransactionTile(data);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
