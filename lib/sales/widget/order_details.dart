import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/sales/widget/delivery_update.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SalesOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onDelete,
    required this.orderId,
  });

  /// SAFE function wrapper for Flutter Web (prevents mouseTracker crash)
  void safeCallback(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'sent':
        return Colors.green;
      case 'cashcollect':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    final status = order['status']?.toString() ?? 'Pending';
    final amount = order['amount']?.toString() ?? '0.00';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final customerName =
        order['customerName']?.toString() ?? 'Unknown Customer';
    final address = order['address']?.toString() ?? 'No Address';
    final createdAt = order['createdAt'];
    final trackingNumber =
        order['trackingNumber']?.toString() ?? 'No Tracking Number';
    final courierPartner = order['courierPartner']?.toString() ?? 'No Courier';

    final courierStatus = order['courierStatus']?.toString() ?? 'Not Synced';

    final courierUpdated = order['courierUpdated'];
    return Center(
      child: SizedBox(
        width: 400,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP SECTION name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          safeCallback(() {
                            Clipboard.setData(
                              ClipboardData(text: customerName),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Customer name copied to clipboard',
                                ),
                              ),
                            );
                          });
                        },
                        child: Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // STATUS CHIP
                    GestureDetector(
                      onTap: () {
                        safeCallback(() {
                          showDeliveryPopup(context, order);
                        });
                      },
                      child: Chip(
                        label: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: firestoreService.getStatusColor(
                          status,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Address row
                TextButton(
                  onPressed: () {
                    safeCallback(() {
                      Clipboard.setData(ClipboardData(text: address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Customer address copied to clipboard'),
                        ),
                      );
                    });
                  },
                  child: Text(
                    'Address: $address',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 4),

                // WhatsApp Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        safeCallback(() {
                          Clipboard.setData(
                            ClipboardData(
                              text: order['trackingNumber'] ?? 'N/A',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tracking copied to clipboard'),
                            ),
                          );
                        });
                      },
                      child: Text('Courier: $trackingNumber'),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.message,
                        color: Colors.green,
                        size: 20,
                      ),
                      onPressed: () {
                        safeCallback(() {
                          sendWhatsApp(order, customerName, amount, items);
                        });
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () {
                        safeCallback(() {
                          sendTrackingWhatsApp(
                            order,
                            customerName,
                            trackingNumber,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.message,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('sales')
                            .doc(orderId)
                            .update({'status': 'cancelled'});
                      },
                    ),
                  ],
                ),
                Text(
                  "Courier Partner: $courierPartner",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),

                Text(
                  "Courier Status: $courierStatus",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

                if (courierUpdated != null)
                  Text(
                    "Updated: ${courierUpdated.toDate()}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 4),

                // Phone
                TextButton(
                  onPressed: () {
                    safeCallback(() {
                      Clipboard.setData(
                        ClipboardData(text: order['phone'] ?? 'N/A'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone number copied to clipboard'),
                        ),
                      );
                    });
                  },
                  child: Text(
                    'Phone: ${order['phone']}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Items: ${items.length}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Amount: \$$amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                if (createdAt != null)
                  Text(
                    'Created: ${createdAt.toDate()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                // EDIT / DELETE
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('need to update this code of line'),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        safeCallback(() {
                          firestoreService.deleteOrder(order['id'], context);
                        });
                      },
                    ),
                  ],
                ),

                // ITEM LIST
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    return Text(
                      '- ${item['name']} (x${item['quantity']})',
                      style: const TextStyle(fontSize: 13),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WhatsApp functions ---
Future<void> sendWhatsApp(order, customer, amount, items) async {
  String phone = cleanPhone(order['phone'] ?? '');
  String message =
      'Dear $customer, Your Order of $items USB is ready. Total = $amount. Delivered via SL Post. Thank you – techtonic.lk';

  final uri = Uri.parse(
    "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> sendTrackingWhatsApp(order, customer, tracking) async {
  String phone = cleanPhone(order['phone'] ?? '');
  String message =
      'Dear $customer, your tracking number is $tracking. Track here: https://techtonic.lk/order-tracking/';

  final uri = Uri.parse(
    "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String cleanPhone(String phone) {
  String p = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (p.startsWith('0')) p = p.substring(1);
  return '94$p';
}
