import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/customer/customer_model.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class SalesOrderCard extends StatelessWidget {
  final SalesModel order;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPdfPressed; // 👈 PDF callback parameter

  const SalesOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onDelete,
    required this.onPdfPressed, // 👈 Required in constructor
  });

  // 🛠️ Function to show the Status Selector Popup Dialog
  void _showStatusDialog(BuildContext context) {
    final List<String> statusOptions = [
      'Web Sales',
      'Pending',
      'Sent',
      'Cash Collect',
      'Return',
    ];

    String localSelectedStatus = statusOptions.contains(order.status)
        ? order.status
        : 'Pending';

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Change Order Status",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: statusOptions.map((status) {
                  return RadioListTile<String>(
                    title: Text(status, style: const TextStyle(fontSize: 14)),
                    value: status,
                    // ignore: deprecated_member_use
                    groupValue: localSelectedStatus,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                    activeColor: Colors.blue.shade800,
                    // ignore: deprecated_member_use
                    onChanged: (String? value) {
                      if (value != null) {
                        setDialogState(() {
                          localSelectedStatus = value;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                await FirestoreService().updateOrderStatus(
                  order.id!,
                  localSelectedStatus,
                );

                Get.back();

                Get.snackbar(
                  "Status Updated",
                  "Order status changed to $localSelectedStatus successfully!",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );

                if (localSelectedStatus == 'Return') {
                  await CustomerController().markCustomerAsReturned(
                    order.customerPhone,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  "Error",
                  "Failed to update status: $e",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text("Update Status"),
          ),
        ],
      ),
      barrierColor: Colors.black54,
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdate = order.courierUpdatedAt != null
        ? "${order.courierUpdatedAt!.toDate().hour}:${order.courierUpdatedAt!.toDate().minute.toString().padLeft(2, '0')}"
        : "Not synced";

    final bool isWebSale = order.status == 'Web Sales';
    final Color badgeBgColor = isWebSale
        ? Colors.purple.shade50
        : Colors.blue.shade100;
    final Color badgeTextColor = isWebSale
        ? Colors.purple.shade800
        : const Color(0xFF0C447C);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Customer Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => copyToClipboard(
                            context,
                            order.customerName ?? "Unknown",
                            "Customer Name",
                          ),
                          child: Text(
                            order.customerName ?? "Unknown",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => copyToClipboard(
                            context,
                            order.customerAddress ?? 'No Address',
                            "Customer Address",
                          ),
                          child: Text(
                            order.customerAddress ?? 'No Address',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => copyToClipboard(
                            context,
                            order.customerPhone,
                            "Customer Phone",
                          ),
                          child: Text(
                            order.customerPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showStatusDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                order.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: badgeTextColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, size: 12, color: badgeTextColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Rs. ${order.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Divider(height: 24, thickness: 0.5),

              // 2. Courier Status & Tracking
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => copyToClipboard(
                              context,
                              order.trackingNumber ?? 'N/A',
                              "Tracking Number",
                            ),
                            child: Text(
                              "Tracking: ${order.trackingNumber ?? 'N/A'}",
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Status: ${order.courierStatus ?? 'Pending'}",
                          style: const TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Last Sync: $lastUpdate",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24, thickness: 0.5),

              // 3. Items List
              if (order.items.isNotEmpty) ...[
                const Text(
                  "Items:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 5),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item['name'] ?? 'Unknown Item'} x${item['quantity'] ?? 1}",
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16, thickness: 0.5),
              ],

              // 4. Action Buttons (Create Courier, Sync, PDF, Edit, Delete)
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () async {
                      try {
                        await FirestoreService().createCourierOrder(order);
                        Get.snackbar(
                          "Success",
                          "Courier Order Created Successfully!",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          e.toString(),
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 30),
                        );
                      }
                    },
                    child: const Text("Create Courier"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    tooltip: "Sync Courier Status",
                    onPressed: () async {
                      if (order.trackingNumber != null &&
                          order.trackingNumber!.isNotEmpty) {
                        try {
                          await FirestoreService().syncCourierStatus(
                            order.id!,
                            order.trackingNumber!,
                          );
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            "Sync failed: $e",
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 30),
                          );
                        }
                      } else {
                        Get.snackbar(
                          "Error",
                          "No tracking number found!",
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 30),
                        );
                      }
                    },
                  ),
                  // 📄 PDF Invoice Button
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFF102A43),
                    ),
                    tooltip: "Print Invoice PDF",
                    onPressed: onPdfPressed,
                  ),
                  TextButton(onPressed: onTap, child: const Text("Edit")),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Delete"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void copyToClipboard(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text("$label copied to clipboard!")));
}
