import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:own/utils/loading.dart';
import 'package:own/utils/sales_summery/sales_summery_controll.dart';

class SalesDashboardView extends StatelessWidget {
  const SalesDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesSummeryControll summeryController = Get.put(
      SalesSummeryControll(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text("Sales DashBoard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (summeryController.isLoading.value) {
            return CustomLoading();
          }
          final data = summeryController.summery.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business overall',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildSummeryCard(
                      title: "Total Revenue",
                      value: "Rs.${data.totalRevenew.toStringAsFixed(2)}",
                      icon: Icons.monetization_on,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildSummeryCard(
                      title: "Total Orders",
                      value: "Rs.${data.totalOrders}",
                      icon: Icons.shopping_bag,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildSummeryCard(
                      title: "income each item",
                      value: "${data.totalRevenew / data.totalOrders}",
                      icon: Icons.ac_unit_rounded,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
              if (data.lastUpdated != null) ...[
                const SizedBox(height: 10),
                Text(
                  "Last Updated: ${data.lastUpdated!.toDate().toString()}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSummeryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
