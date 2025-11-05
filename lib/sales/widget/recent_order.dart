// lib/widgets/recent_order_item.dart
import 'package:flutter/material.dart';
import 'package:own/app/constant/app_constant.dart';
import 'package:own/sales/order_model.dart';

class RecentOrderItem extends StatelessWidget {
  final Order order;

  const RecentOrderItem({super.key, required this.order});

  // Helper to get status color and text
  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (order.status) {
      case OrderStatus.pending:
        chipColor = AppColors.pendingStatus;
        statusText = 'Pending';
        break;
      case OrderStatus.sent:
        chipColor = AppColors.sentStatus;
        statusText = 'Sent';
        break;
      case OrderStatus.cashCollect:
        chipColor = AppColors.cashCollectStatus;
        statusText = 'Collected';
        break;
      default:
        chipColor = Colors.red;
        statusText = 'cancel';
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customerName,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${order.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
