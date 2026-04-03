import 'package:flutter/material.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/sales/order_model.dart';

class DashboardProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Stats
  Map<String, dynamic>? salesStats;
  bool isLoadingStats = false;

  // Recent Orders
  List<Order> recentOrders = [];

  // Fetch sales statistics
  Future<void> fetchSalesStatistics() async {
    try {
      isLoadingStats = true;
      notifyListeners();
      salesStats = await _firestoreService.getSalesStatistics();
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  // Listen to recent orders
  void listenToRecentOrders() {
    _firestoreService.getAllSalesOrders().listen((orders) {
      recentOrders = orders
          .map((data) => Order.fromMap(data))
          .where(
            (order) => order.status == OrderStatus.pending,
          ) // ✅ Only Pending
          .toList();
      notifyListeners();
    });
  }

  void logout(BuildContext context) {}
}
