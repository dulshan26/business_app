import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:own/api_handler/royal.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final CollectionReference salesCollection = FirebaseFirestore.instance
      .collection('sales_new');

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
  // FirestoreService.dart එකේ මේ විදිහට හදන්න
  Stream<List<SalesModel>> getAllSalesOrders() {
    return salesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SalesModel.fromSnapshot(doc),
              ) // 👈 මෙතනදී තමයි ඔයාගේ අර ෆැක්ටරි එක පාවිච්චි වෙන්නේ
              .toList(),
        );
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

  // Delete - Delete sales order
  // 💡 ඔයාගේ පරණ deleteSalesOrder එක වෙනුවට මේක ආදේශ කරන්න:
  Future<void> deleteSalesOrder(String orderId) async {
    try {
      // 1. 🔍 Delete කරන්න කලින් මේ Sale එකේ දත්ත Firestore එකෙන් කියවා ගැනීම
      DocumentSnapshot saleDoc = await _db
          .collection('sales_new')
          .doc(orderId)
          .get();

      if (!saleDoc.exists) {
        Get.snackbar("Error", "Sales order not found!");
        return;
      }

      // 2. දත්ත ලබා ගැනීම
      var saleData = saleDoc.data() as Map<String, dynamic>;
      List<dynamic> items = saleData['items'] ?? [];
      double totalAmount =
          double.tryParse(saleData['totalAmount'].toString()) ?? 0.0;

      // 3. 🔥 WriteBatch එකක් ආරම්භ කිරීම
      WriteBatch batch = _db.batch();

      // References සකසා ගැනීම
      DocumentReference saleRef = _db.collection('sales_new').doc(orderId);
      DocumentReference globalSalesSummaryRef = _db
          .collection('sales_summary')
          .doc('overall');

      // 4. 🗑️ Sale Document එක Delete කරන්න Batch එකට දැමීම
      batch.delete(saleRef);

      // 5. 📉 Summary එකෙන් මුදල් සහ ඕඩර් ගණන අඩු කිරීම
      batch.set(globalSalesSummaryRef, {
        'total_revenue': FieldValue.increment(
          -totalAmount,
        ), // බිලේ ගාන සමස්ත එකතුවෙන් අඩු කරයි
        'total_orders': FieldValue.increment(-1), // ඕඩර් ගණන 1කින් අඩු කරයි
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 6. 🔄 Items ලැයිස්තුව හරහා යමින් Stock එක ආපහු වැඩි කිරීම සහ Transaction එකක් ලියා තැබීම
      for (var item in items) {
        String productId = item['id'] ?? item['item_id'].toString();
        String itemName = item['name'] ?? item['item_name'] ?? 'Unknown Item';
        int quantitySold = int.tryParse(item['quantity'].toString()) ?? 1;

        // සටහන: quantitySold එක කලින් සේව් වෙලා තිබ්බේ සෘණ අගයක් (-5) විදිහට නෙමෙයි,
        // සාමාන්‍ය ධන අගයක් (5) විදිහට නම්, අපි දැන් ඒක ආපහු එකතු (Add) කරන්න ඕනේ.
        // සේල් එකේ තිබ්බ ගාන ධන අගයක් නම්, ඒක ආපහු එකතු කරන්න FieldValue.increment(quantitySold) දාන්න.
        // හැබැයි ඔයා SalesModel එකේම quantity එක -5 විදියට සේව් කරලා තිබ්බොත්, මෙතනට වන්න ඕනේ ප්ලස් (Abs) අගයයි.
        int qtyToReturn = quantitySold
            .abs(); // හැමවිටම ධන අගයක් ලබාගැනීමට (.abs())

        DocumentReference productRef = _db.collection('stock').doc(productId);

        // Stock එක ආපහු වැඩි කරයි (බඩු ආපහු ආ නිසා)
        batch.update(productRef, {
          'balance': FieldValue.increment(qtyToReturn),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // 📝 Item එකේ /transactions සබ්-කොലෙක්ෂන් එකට කැන්සල් වුන බවට Entry එකක් දැමීම
        DocumentReference transRef = productRef
            .collection('transactions')
            .doc();
        batch.set(transRef, {
          'quantity': qtyToReturn, // බඩු එකතු වූ නිසා ධන අගයක් (+5)
          'type': 'in', // ආපහු කඩේට ආ නිසා 'in' හෝ 'returned' දාන්න පුළුවන්
          'note': 'Order Deleted / Cancelled (Order ID: $orderId)',
          'timestamp': FieldValue.serverTimestamp(),
          'item_name': itemName,
        });
      }

      // 7. 🔥 සියලුම වෙනස්කම් එකවරම Database එකට යැවීම (Commit)
      await batch.commit();

      Get.snackbar(
        "Success",
        "Sales order deleted and stock restored successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete order: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      throw Exception('Failed to delete sales order: $e');
    }
  }

  Future<void> syncCourierStatus(String orderId, String waybill) async {
    try {
      String? status = await CurfoxService().getCurrentStatus(waybill);
      if (status != null) {
        await salesCollection.doc(orderId).update({
          "courierStatus": status,
          "courierUpdated": FieldValue.serverTimestamp(), // මෙය තිබිය යුතුමයි
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Error syncing status: $e");
    }
  }

  //GetX with firebase
  void deleteOrderShow(String orderId, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await deleteSalesOrder(orderId); // කෙලින්ම ID එක පාවිච්චි කරන්න
              Navigator.pop(context); // Dialog එක වහන්න
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> syncAllCourierStatuses() async {
    try {
      // 1. Sent status එකේ තියෙන ඔක්කොම orders එකවර කියවා ගැනීම
      final querySnapshot = await salesCollection
          .where('status', isEqualTo: 'Sent')
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar(
          "Info",
          "No pending courier orders to sync.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // 💡 Loading එකක් පෙන්වන්න (Optional UI Feedback)
      Get.snackbar(
        "Syncing...",
        "Updating all courier statuses in background...",
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
      );

      // 2. හැම Document එකකටම අදාළ Sync Task එක Future ලැයිස්තුවක් විදිහට සකසා ගැනීම
      List<Future<void>> syncTasks = querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        String? trackingNumber = data['trackingNumber'];

        if (trackingNumber != null && trackingNumber.isNotEmpty) {
          try {
            // Curfox API එකෙන් එකවර දත්ත ලබා ගැනීම
            String? status = await CurfoxService().getCurrentStatus(
              trackingNumber,
            );

            if (status != null) {
              // Firestore Update එක සිදු කිරීම
              await salesCollection.doc(doc.id).update({
                "courierStatus": status,
                "courierUpdated": FieldValue.serverTimestamp(),
              });
            }
          } catch (e) {
            print("Error syncing order ${doc.id}: $e");
            // එක ඕඩර් එකක් ෆේල් වුනත් අනිත් ඒවාට බාධාවක් වෙන්නේ නැහැ
          }
        }
      }).toList();

      // 3. 🔥 🔥 වැදගත්ම කොටස: සියලුම API Calls සහ Updates එකවර Parallel රන් කිරීම
      await Future.wait(syncTasks);

      Get.snackbar(
        "Success",
        "All courier statuses updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Bulk sync failed: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // FirestoreService.dart
  Future<void> createCourierOrder(SalesModel order) async {
    // Check if tracking number is already available
    if (order.trackingNumber != null) {
      Get.snackbar(
        "Already Created",
        "Courier order already exists. Tracking Number: ${order.trackingNumber}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber[800],
        colorText: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
      return; // Stop execution right here
    }
    try {
      final response = await http.post(
        Uri.parse("https://v1.api.curfox.com/api/public/merchant/order/single"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization":
              "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYjFiNDk3OWM1YjEyNjEwNjUxMGFhZDMyMDQ0MzBiMWE0NWYyZTFiMzAzOTIzMTQ3ZjdjM2YyNWEzMGZkMDU0MzdhZWZjNmJiOTVkZWI2OTEiLCJpYXQiOjE3NzI3MzU4MzMuMjM2NDYzLCJuYmYiOjE3NzI3MzU4MzMuMjM2NDY1LCJleHAiOjQ5Mjg0MDk0MzMuMjIyMzE0LCJzdWIiOiI0Njc0Iiwic2NvcGVzIjpbXX0.jVbxQXE8AOGvYuWPQmDGA7VyYvPyw73AnyiCpGgdd0XD7GQCtMj5HLn0YNADASZwWOxRxK9J92OB0CW3KD_ZUtku7VYIbb8SYKOYDzBNrdt8EfiM7cKMf8vWaD22jnwi33_TEEdWzQxuI5HMqkq0AiKOm93lKgt94SGmeSl_xlWORKBENB4qvawCiQhRgluMnyxInC7mmbPGgHY1Mx_4IZ5nEXto3C6wrlLdfPJNTlWnJPALeHKiNPRLD6kHS0-Mo_wotlddLRuKSfj19kxkazfBm-cuH8cJj76pFCuVKbQCWzC-ok7gK2-ZwO3nvEq9VnEQrG62bxkgFe8orEZIfm3Saw99sbUr7EwoHOvMircz4FMHm-ls5c8VqUpy81xn8TyYeZ6mTyZk0oJ0mVso_JbN5wU6hmKmxX-amhA2UTQ1f20Ic61JVskkmZjkmDmdBQBU2yribDqzD06_SH3I7n8KueHYNXOElHo-D1Gp2wU05zTdROMurfegGzTvCeR8v6lAaDygLXyG2quK6RF0LN_kwXat6JqRCAuyedHfzts0TEe1Yps8LY1LfyW4PtcFaZcUoLPjQwsDcM6yE0237I1qDMNhobp_qB_3V1xkenN7sPkLn47iRodN7-PoFMzG3xzffZvm4tVJBRcKuvxgTSCDf2GkJZSbz20RRv7kDZo", // මෙතන Token එක දාන්න
          "X-tenant": "royalexpress",
        },
        body: jsonEncode({
          "general_data": {
            "merchant_business_id": "4590",
            "origin_city_name": "Kotte",
            "origin_state_name": "Colombo",
          },
          "order_data": [
            {
              "order_no": order.id,
              "customer_name": order.customerName,
              "customer_address": order.customerAddress,
              "customer_phone": order.customerPhone,
              "customer_secondary_phone": order.custonerPhone2 ?? "",
              "destination_city_name": "Colombo 02",
              "destination_state_name": "Colombo",
              "cod": order.totalAmount,
              "weight": 1.0,
              "description": "Fragile item",
              "remark": "Handle with care",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String waybill =
            data['data'][0]; // API එකෙන් එන Tracking Number එක

        // Firestore එකේ අදාල Order එකට Tracking Number එක සහ status එක save කරන්න
        await FirebaseFirestore.instance
            .collection("sales_new")
            .doc(order.id)
            .update({
              "trackingNumber": waybill,
              "courierStatus": "Order Created",
              "courierPartner": "Royal Courier",
              "courierCost": 425.0,
              'status': 'Sent', // Sales order status එක update කරන්න
              "courierUpdated": FieldValue.serverTimestamp(),
            });
        Get.snackbar(
          "Success",
          "Courier status updated!",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 30),
        );
      } else {
        throw Exception("Failed to create order: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('sales_new') // modify this to match your collection name
        .doc(orderId)
        .update({'status': newStatus});
  }
}
