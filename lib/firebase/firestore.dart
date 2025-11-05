import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:own/sales/order_model.dart';
import 'package:own/sales/widget/sales_edit.dart';
import 'package:url_launcher/url_launcher.dart';

class FirestoreService {
  final CollectionReference salesCollection = FirebaseFirestore.instance
      .collection('sales');

  // Create - Add new sales order
  Future<String> createSalesOrder(Map<String, dynamic> salesData) async {
    try {
      // Add timestamp
      salesData['createdAt'] = FieldValue.serverTimestamp();
      salesData['updatedAt'] = FieldValue.serverTimestamp();
      salesData['createdby'] = FirebaseAuth.instance.currentUser!.uid;

      final docRef = await salesCollection.add(salesData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create sales order: $e');
    }
  }

  // Read - Get all sales orders
  Stream<List<Map<String, dynamic>>> getAllSalesOrders() {
    return salesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
        });
  }

  // Read - Get single sales order by ID
  Future<Map<String, dynamic>?> getSalesOrderById(String orderId) async {
    try {
      final doc = await salesCollection.doc(orderId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sales order: $e');
    }
  }

  // Read - Get sales orders by status
  Stream<List<Map<String, dynamic>>> getSalesOrdersByStatus(String status) {
    return salesCollection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
        });
  }

  // Update - Update sales order
  Future<void> updateSalesOrder(
    String orderId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await salesCollection.doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update sales order: $e');
    }
  }

  // Update - Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await salesCollection.doc(orderId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Delete - Delete sales order
  Future<void> deleteSalesOrder(String orderId) async {
    try {
      await salesCollection.doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete sales order: $e');
    }
  }

  // Get sales statistics
  Future<Map<String, dynamic>> getSalesStatistics() async {
    try {
      final totalSalesQuery = await salesCollection.get();
      final pendingQuery = await salesCollection
          .where('status', isEqualTo: 'Pending')
          .get();
      final sentQuery = await salesCollection
          .where('status', isEqualTo: 'Sent')
          .get();
      final collectedQuery = await salesCollection
          .where('status', isEqualTo: 'CashCollect')
          .get();

      double totalAmount = 0;
      for (var doc in totalSalesQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalAmount += (data['amount'] ?? 0).toDouble();
      }

      return {
        'totalOrders': totalSalesQuery.docs.length,
        'totalAmount': totalAmount,
        'pendingOrders': pendingQuery.docs.length,
        'sentOrders': sentQuery.docs.length,
        'collectedOrders': collectedQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get sales statistics: $e');
    }
  }

  // Search sales orders by customer name or phone
  Stream<List<Map<String, dynamic>>> searchSalesOrders(String query) {
    return salesCollection.orderBy('customerName').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final customerName = (data['customerName'] ?? '')
                .toString()
                .toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            final searchQuery = query.toLowerCase();

            return customerName.contains(searchQuery) ||
                phone.contains(searchQuery) ||
                doc.id.contains(query);
          })
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  }

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

  void editOrder(Map<String, dynamic> order, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          EditSalesOrderDialog(order: order, onOrderUpdated: () {}),
    );
  }

  void deleteOrder(String? orderId, BuildContext context) {
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
                await deleteSalesOrder(orderId);
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

  //credit card transactions information firestore
  final CollectionReference creidtCard = FirebaseFirestore.instance.collection(
    'credit_card',
  );

  Future<void> addTransaction({
    required String decription,
    required String date,
    required String card,
    required double amount,
    required String type,
    required String holder,
  }) async {
    try {
      await creidtCard.add({
        'description': decription,
        'date': date,
        'card': card,
        'amount': amount,
        'type': type,
        'holder': holder,
        'createdAt': FieldValue.serverTimestamp(),
        'createdby': FirebaseAuth.instance.currentUser!.uid,
      });
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  //get transaction details
  Stream<List<Map<String, dynamic>>> getTransactions() {
    return creidtCard.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsByCard(String card) {
    return creidtCard
        .where('card', isEqualTo: card)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
          }).toList();
        });
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await creidtCard.doc(transactionId).delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  //get sales data by catogory 22/10/2025
  Map<String, List<Map<String, dynamic>>> groupSalesByStatus(
    List<Map<String, dynamic>> salesOrders,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var order in salesOrders) {
      final status = order['status']?.toString() ?? 'Pending';
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(order);
    }

    return grouped;
  }

  ///Status change save update firebase code
  ///
}
