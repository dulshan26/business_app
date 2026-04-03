import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:own/sales/pages/stock/add_stock.dart';
import 'package:own/sales/pages/stock/stock.dart';

class StockPage1 extends StatelessWidget {
  const StockPage1({super.key});

  Future<int> getSalesCount(int itemId) async {
    final salesSnap = await FirebaseFirestore.instance
        .collection('sales')
        .get();

    int total = 0;

    for (var sale in salesSnap.docs) {
      final data = sale.data();
      final items = data['items'];

      if (items == null || items is! List) continue;

      for (var item in items) {
        if (item is! Map) continue;

        final String saleItemId = item['id'].toString();
        final int qty = (item['quantity'] is int)
            ? item['quantity']
            : int.tryParse(item['quantity'].toString()) ?? 0;

        if (saleItemId == itemId.toString()) {
          total += qty;
        }
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("stock")
            .orderBy("item_id")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final itemId = data["item_id"];
              final itemName = data["item_name"];
              final balance = data["balance"];

              return FutureBuilder<int>(
                future: getSalesCount(itemId),
                builder: (context, snap) {
                  final totalSales = snap.data ?? 0;
                  final currentBalance = (balance - totalSales);

                  return Card(
                    margin: const EdgeInsets.all(10),
                    color: Colors.grey.shade900,
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          currentBalance.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        itemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        "ID: $itemId\nSales: $totalSales  Stock: $balance",
                        style: TextStyle(
                          color: currentBalance < 0 ? Colors.red : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
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
