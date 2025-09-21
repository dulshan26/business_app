// lib/services/firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:own/models/order_model.dart';

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
}
