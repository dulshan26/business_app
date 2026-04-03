import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:own/api_handler/royal.dart';
import 'package:own/sales/order_model.dart';

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
      double collectedAmount = 0;
      for (var doc in totalSalesQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalAmount += (data['amount'] ?? 0).toDouble();

        if ((data['status'] ?? '') == 'CashCollect') {
          collectedAmount += (data['amount'] ?? 0).toDouble();
        }
      }
      return {
        'totalOrders': totalSalesQuery.docs.length,
        'totalAmount': totalAmount,
        'pendingOrders': pendingQuery.docs.length,
        'sentOrders': sentQuery.docs.length,
        'collectedOrders': collectedQuery.docs.length,
        'collectedAmount': collectedAmount,
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

  void deleteOrder(String? orderId, BuildContext context) {
    Future<void> confirmDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true && orderId != null) {
        await deleteSalesOrder(orderId);
      }
    }

    confirmDelete();
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

  Future<void> updateCourierStatus(String orderId, String status) async {
    await salesCollection.doc(orderId).update({
      "courierStatus": status,
      "courierUpdate": FieldValue.serverTimestamp(),
    });
  }

  Future<void> syncCourierStatus(String orderId, String waybill) async {
    String? status = await CurfoxService().getCurrentStatus(waybill);
    if (status != null) {
      await FirestoreService().updateCourierStatus(orderId, status);
    }
  }
}
