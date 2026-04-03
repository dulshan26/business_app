import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/sales/widget/summery_card.dart';

class SummeryPage extends StatefulWidget {
  const SummeryPage({super.key});

  @override
  State<SummeryPage> createState() => _SummerypageState();
}

class _SummerypageState extends State<SummeryPage> {
  final FirestoreService firestoreservice = FirestoreService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text('Sales overall', style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: FutureBuilder<Map<String, dynamic>>(
            future: firestoreservice.getSalesStatistics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No data available'));
              } else {
                final stats = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    children: [
                      SummaryCard(
                        title: 'Total Revernew',
                        value: "Rs.${stats['totalAmount'].toString()}",
                        icon: Icons.shopping_cart,
                        iconColor: Colors.blue,
                      ),
                      SummaryCard(
                        title: 'Completed Orders',
                        value: stats['collectedAmount'].toString(),
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                      ),
                      SummaryCard(
                        title: 'Pending Orders',
                        value: stats['pendingOrders'].toString(),
                        icon: Icons.hourglass_top_rounded,
                        iconColor: Colors.orange,
                      ),
                      SummaryCard(
                        title: 'Cancelled Orders',
                        value: stats['cancelledOrders'].toString(),
                        icon: Icons.cancel,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
