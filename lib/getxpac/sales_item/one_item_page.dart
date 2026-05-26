import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 💡 දින සහ වේලාවන් හැඩගැස්වීමට (Format)
import 'package:own/getxpac/sales_item/item_controller.dart';

class StockHistoryPage extends StatelessWidget {
  final String productId;
  final String itemName;

  const StockHistoryPage({
    super.key,
    required this.productId,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    // Controller එක සාදා මෙම පිටුවට සම්බන්ධ කිරීම (Dependency Injection)
    final StockHistoryController controller = Get.put(
      StockHistoryController(productId: productId),
      tag: productId, // විවිධ products වලට මාරු වන විට අවුල් නොවීමට tag එකක් දේ
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("$itemName - History"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        // දත්ත Load වන වෙලාවට පෙන්වන Loading Screen එක
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // කිසිදු transaction එකක් නැති විට පෙන්වන Screen එක
        if (controller.transactions.isEmpty) {
          return const Center(
            child: Text(
              "No transactions found for this item.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        // දත්ත ලැයිස්තුව පෙන්වන කොටස
        return ListView.builder(
          itemCount: controller.transactions.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final trans = controller.transactions[index];

            // "in" ද "out" ද යන්න මත වර්ණය සහ අයිකනය තීරණය කිරීම
            final bool isIn = trans['type'] == 'in';
            final Color statusColor = isIn
                ? Colors.green.shade600
                : Colors.red.shade600;
            final IconData statusIcon = isIn
                ? Icons.arrow_downward
                : Icons.arrow_upward;

            // Timestamp එක ලස්සනට දින සහ වේලාවට හැරවීම
            String formattedDate = "Just now";
            if (trans['timestamp'] != null) {
              var timestamp = trans['timestamp'] as Timestamp;
              formattedDate = DateFormat(
                'yyyy-MM-dd  hh:mm a',
              ).format(timestamp.toDate());
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // වර්ණවත් අයිකනය (In/Out පෙන්වීමට)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),

                    // විස්තර කොටස
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isIn ? "Stock Added (Restock)" : "Stock Out (Sale)",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trans['note'] != ""
                                ? "${trans['note']}"
                                : "No notes attached.",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ප්‍රමාණයන් (Quantity & Balance) පෙන්වන කොටස
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${isIn ? '+' : '-'}${trans['quantity']}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Bal: ${trans['balance_after']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
