import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/sales/widget/delivery_update.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const SalesOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onDelete,
  });

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'Pending':
        return Colors.orange;
      case 'Sent':
        return Colors.green;
      case 'CashCollect':
        return Colors.blue;
      case 'Cancelled':
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
    final items = List<Map<String, dynamic>>.from(order['items'] ?? "No Items");
    final customerName =
        order['customerName']?.toString() ?? 'Unknown Customer';
    final address = order['address']?.toString() ?? 'No Address';
    final createdAt = order['createdAt'];
    final trackingNumber =
        order['trackingNumber']?.toString() ?? 'No Tracking Number';
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: customerName));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Customer name copied to clipboard',
                              ),
                            ),
                          );
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

                    GestureDetector(
                      onTap: () => showDeliveryPopup(context, order),
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
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer address copied to clipboard'),
                      ),
                    );
                  },
                  child: Text(
                    'Address: $address',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: order['trackingNumber'] ?? 'N/A'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tracking copied to clipboard'),
                          ),
                        );
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
                        Future<void> sendWhatsAppMessage(
                          String phone,
                          String message,
                        ) async {
                          // Clean up the phone number (remove spaces, +, -, etc.)
                          String cleanPhone = phone.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );

                          // If number starts with 0, remove it
                          if (cleanPhone.startsWith('0')) {
                            cleanPhone = cleanPhone.substring(1);
                          }

                          // Add Sri Lanka country code (+94)
                          cleanPhone = '94$cleanPhone';

                          final uri = Uri.parse(
                            "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
                          );

                          if (!await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open WhatsApp'),
                              ),
                            );
                          }
                        }

                        final phone = order['phone'] ?? '';
                        final message =
                            'Dear $customerName, Your Order of $items USB is ready.                                                 total price is $amount                                            We have using SL post for deliver your parcel seftly,be patient, and we are form techtonic.lk';
                        sendWhatsAppMessage(phone, message);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () {
                        Future<void> sendWhatsAppMessage(
                          String phone,
                          String message,
                        ) async {
                          // Clean up the phone number (remove spaces, +, -, etc.)
                          String cleanPhone = phone.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );

                          // If number starts with 0, remove it
                          if (cleanPhone.startsWith('0')) {
                            cleanPhone = cleanPhone.substring(1);
                          }

                          // Add Sri Lanka country code (+94)
                          cleanPhone = '94$cleanPhone';

                          final uri = Uri.parse(
                            "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
                          );

                          if (!await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open WhatsApp'),
                              ),
                            );
                          }
                        }

                        final phone = order['phone'] ?? '';
                        final message =
                            'Dear $customerName, your order tracking number is $trackingNumber  from . Your parcel is being shipped https://techtonic.lk/order-tracking/. Please allow time for delivery. Thank you for your patience.';
                        sendWhatsAppMessage(phone, message);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: order['phone'] ?? 'N/A'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied to clipboard'),
                      ),
                    );
                  },
                  child: Text(
                    'Phone: ${order['phone'] ?? 'N/A'}',
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
                    'Created: ${(createdAt.toDate())}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          firestoreService.editOrder(order, context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          firestoreService.deleteOrder(order['id'], context),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final itemName = item['name'] ?? 'Unknown';
                    final quantity = item['quantity'] ?? 1;
                    return Text(
                      '- $itemName (x$quantity)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
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
