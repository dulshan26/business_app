// lib/pages/sales_list_page.dart
import 'package:flutter/material.dart';
import 'package:own/firebase/firestore.dart';

import 'package:own/sales/pages/salepage/sales_page_summery.dart';
import 'package:own/sales/widget/order_details.dart';

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
                MaterialPageRoute(builder: (context) => const StockPage1()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
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
                    final FirestoreService firestoreService =
                        FirestoreService();
                    return ListView(
                      children: firestoreService
                          .groupSalesByStatus(salesOrders)
                          .entries
                          .map((entry) {
                            final status = entry.key;
                            final orders = entry.value;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    status,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: firestoreService
                                        .getStatusColor(status),
                                    child: Text(
                                      status[0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  children: orders.map((order) {
                                    return SalesOrderCard(
                                      order: {...order},
                                      onTap: () {},
                                      onDelete: () {},
                                      orderId: '',
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockPage1()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
