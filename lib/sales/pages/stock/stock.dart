import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:own/sales/pages/stock/add_stock.dart';
import 'package:own/sales/widget/gluss_card.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

final stockCollection = FirebaseFirestore.instance.collection('stock');

class _StockPageState extends State<StockPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Stock Management'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.goNamed('dashboard');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stockCollection.orderBy('item_id').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Mukut Save Karla Na",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            padding: EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;

              return GlassCard(
                title: data['item_name'] ?? "No Name",
                subtitle: data['description'] ?? "",
                leading: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),

                  child: Text(
                    data['item_id'].toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                onEdit: () => showAddStockItemDialog(context, docToEdit: doc),
                onDelete: () => stockCollection.doc(doc.id).delete(),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton.extended(
              heroTag: 'addStocKPage',
              onPressed: () async {
                final snapshot = await stockCollection.get();

                var nextId = snapshot.docs.length + 1;
                if (snapshot.docs.isNotEmpty) {
                  nextId = nextId;
                }

                // ignore: use_build_context_synchronously
                showAddStockItemDialog(
                  context,
                  nextItemId: nextId,
                ); // Example nextItemId
              },
              icon: Icon(Icons.add),
              label: const Text('Add Stock Item'),
            ),
            FloatingActionButton.extended(
              heroTag: 'stockTransaction',
              onPressed: () {
                context.goNamed('transaction');
              },

              label: Text('Transaction Page'),
            ),
          ],
        ),
      ),
    );
  }
}
