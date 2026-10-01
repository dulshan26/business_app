import 'package:cloud_firestore/cloud_firestore.dart';

class SalesSummery {
  final int totalOrders;
  final double totalRevenew;
  final Timestamp? lastUpdated;

  SalesSummery({
    required this.totalOrders,
    required this.totalRevenew,
    this.lastUpdated,
  });

  factory SalesSummery.fromSnapshot(DocumentSnapshot docs) {
    var data = docs.data() as Map<String, dynamic>?;

    return SalesSummery(
      totalOrders: int.tryParse(data?['total_orders']?.toString() ?? '0') ?? 0,
      totalRevenew:
          double.tryParse(data?['total_revenue']?.toString() ?? "0.0") ?? 0.0,
      lastUpdated: data?['last_updated'] as Timestamp,
    );
  }
}
