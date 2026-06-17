import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 🔄 Update - Update sales order and adjust summary if totalAmount changed
  Future<void> updateSalesOrder(
    String orderId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference saleRef = salesCollection.doc(orderId);
      DocumentReference globalSalesSummaryRef = _db
          .collection('sales_summary')
          .doc('overall');

      WriteBatch batch = _db.batch();

      // 🌟 බිලේ මුදල වෙනස් වෙලා තියෙනවා නම් විතරක් summary එක වෙනස් කරනවා
      if (updates.containsKey('totalAmount')) {
        // 1. පරණ දත්ත කියවා ගැනීම
        DocumentSnapshot oldDoc = await saleRef.get();
        if (oldDoc.exists) {
          var oldData = oldDoc.data() as Map<String, dynamic>;
          double oldAmount =
              double.tryParse(oldData['totalAmount'].toString()) ?? 0.0;
          double newAmount =
              double.tryParse(updates['totalAmount'].toString()) ?? 0.0;

          // 🧮 වෙනස සෙවීම (උදා: 2000 - 1500 = +500 එකතු වේ | 1200 - 1500 = -300 අඩු වේ)
          double amountDifference = newAmount - oldAmount;

          batch.set(globalSalesSummaryRef, {
            'total_revenue': FieldValue.increment(amountDifference),
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // 2. ඕඩර් එකේ Updates ටික Batch එකට දමා Commit කිරීම
      batch.update(saleRef, updates);
      await batch.commit();
    } catch (e) {
      Get.snackbar("UPDATE ERROR", "Failed to update sales order: $e");
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
            Get.snackbar(
              "Error",
              "Error syncing order ${doc.id}: $e",
              snackPosition: SnackPosition.BOTTOM,
            );
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
    try {
      // 1. Fetch live document from Firebase to verify state and ensure tracking doesn't exist
      final docSnapshot = await FirebaseFirestore.instance
          .collection("sales_new")
          .doc(order.id)
          .get();

      if (docSnapshot.exists) {
        final dbData = docSnapshot.data();
        if (dbData != null &&
            dbData['trackingNumber'] != null &&
            dbData['trackingNumber'].toString().isNotEmpty) {
          Get.snackbar(
            "Already Created",
            "Courier order already exists. Tracking Number: ${dbData['trackingNumber']}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.amber[800],
            colorText: Colors.white,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(12),
          );
          return;
        }
      }

      // 🌟 FIX: Safe Parsing for Data Types required by Curfox API Docs
      // Convert double amount (e.g. 1550.50) safely to an integer (e.g. 1551)
      final int safeCodAmount = (order.totalAmount).round();

      // Ensure string fields are clean and fallback smoothly
      final String targetCity = order.destinationCity ?? "Colombo 02";
      final String targetState = order.destinationState ?? "Colombo";

      // 2. Build and execute API Request payload
      final response = await http.post(
        Uri.parse("https://v1.api.curfox.com/api/public/merchant/order/single"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization":
              "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYjFiNDk3OWM1YjEyNjEwNjUxMGFhZDMyMDQ0MzBiMWE0NWYyZTFiMzAzOTIzMTQ3ZjdjM2YyNWEzMGZkMDU0MzdhZWZjNmJiOTVkZWI2OTEiLCJpYXQiOjE3NzI3MzU4MzMuMjM2NDYzLCJuYmYiOjE3NzI3MzU4MzMuMjM2NDY1LCJleHAiOjQ5Mjg0MDk0MzMuMjIyMzE0LCJzdWIiOiI0Njc0Iiwic2NvcGVzIjpbXX0.jVbxQXE8AOGvYuWPQmDGA7VyYvPyw73AnyiCpGgdd0XD7GQCtMj5HLn0YNADASZwWOxRxK9J92OB0CW3KD_ZUtku7VYIbb8SYKOYDzBNrdt8EfiM7cKMf8vWaD22jnwi33_TEEdWzQxuI5HMqkq0AiKOm93lKgt94SGmeSl_xlWORKBENB4qvawCiQhRgluMnyxInC7mmbPGgHY1Mx_4IZ5nEXto3C6wrlLdfPJNTlWnJPALeHKiNPRLD6kHS0-Mo_wotlddLRuKSfj19kxkazfBm-cuH8cJj76pFCuVKbQCWzC-ok7gK2-ZwO3nvEq9VnEQrG62bxkgFe8orEZIfm3Saw99sbUr7EwoHOvMircz4FMHm-ls5c8VqUpy81xn8TyYeZ6mTyZk0oJ0mVso_JbN5wU6hmKmxX-amhA2UTQ1f20Ic61JVskkmZjkmDmdBQBU2yribDqzD06_SH3I7n8KueHYNXOElHo-D1Gp2wU05zTdROMurfegGzTvCeR8v6lAaDygLXyG2quK6RF0LN_kwXat6JqRCAuyedHfzts0TEe1Yps8LY1LfyW4PtcFaZcUoLPjQwsDcM6yE0237I1qDMNhobp_qB_3V1xkenN7sPkLn47iRodN7-PoFMzG3xzffZvm4tVJBRcKuvxgTSCDf2GkJZSbz20RRv7kDZo",
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
              "order_no": order.id.toString(),
              "customer_name": order.customerName ?? "Customer",
              "customer_address":
                  order.customerAddress ?? "No Address Provided",
              "customer_phone": order.customerPhone,
              "customer_secondary_phone": order.custonerPhone2 ?? "",
              "destination_city_name":
                  targetCity, // Curfox API එකට City Name එක යවන්න ඕනේ, ID එක නෙමෙයි
              "destination_state_name": targetState,
              "cod":
                  safeCodAmount, // 🌟 FIXED: Passes strictly as Integer data type
              "weight": 1.0, // Passes as Double data type
              "description": "please correct distination city before send",
              "remark": "please correct distination city before send",
            },
          ],
        }),
      );

      // 3. Process API Response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> responseWaybillList = responseData['data'];
        final String generatedWaybill = responseWaybillList[0].toString();

        // 4. Update the source tracking info in Firestore
        await FirebaseFirestore.instance
            .collection("sales_new")
            .doc(order.id)
            .update({
              "trackingNumber": generatedWaybill,
              "courierStatus": "Order Created",
              "courierPartner": "Royal Courier",
              "courierCost": 425.0,
              "status": "Sent",
              "courierUpdated": FieldValue.serverTimestamp(),
            });

        Get.snackbar(
          "Success",
          "Courier order successfully created! Waybill: $generatedWaybill",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[800],
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        // 🌟 IMPROVED ERROR PARSING: Reads detailed validation rejections straight from Curfox
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        String errorMessage = errorBody['message'] ?? "Validation Error";

        if (errorBody.containsKey('errors')) {
          final Map<String, dynamic> detailedErrors = errorBody['errors'];
          // Extracts the first exact error array description if available
          if (detailedErrors.values.isNotEmpty &&
              detailedErrors.values.first is List) {
            errorMessage = detailedErrors.values.first[0].toString();
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      Get.snackbar(
        "Submission Failed",
        e.toString().replaceAll("Exception: ", ""),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[900],
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
      );
    }
  }

  //city loaded
  Future<List<Map<String, dynamic>>> loadCurfoxCities({
    required String token,
    required String tenant,
  }) async {
    try {
      final String url =
          "https://v1.api.curfox.com/api/public/merchant/city?noPagination=1";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization":
              "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYjFiNDk3OWM1YjEyNjEwNjUxMGFhZDMyMDQ0MzBiMWE0NWYyZTFiMzAzOTIzMTQ3ZjdjM2YyNWEzMGZkMDU0MzdhZWZjNmJiOTVkZWI2OTEiLCJpYXQiOjE3NzI3MzU4MzMuMjM2NDYzLCJuYmYiOjE3NzI3MzU4MzMuMjM2NDY1LCJleHAiOjQ5Mjg0MDk0MzMuMjIyMzE0LCJzdWIiOiI0Njc0Iiwic2NvcGVzIjpbXX0.jVbxQXE8AOGvYuWPQmDGA7VyYvPyw73AnyiCpGgdd0XD7GQCtMj5HLn0YNADASZwWOxRxK9J92OB0CW3KD_ZUtku7VYIbb8SYKOYDzBNrdt8EfiM7cKMf8vWaD22jnwi33_TEEdWzQxuI5HMqkq0AiKOm93lKgt94SGmeSl_xlWORKBENB4qvawCiQhRgluMnyxInC7mmbPGgHY1Mx_4IZ5nEXto3C6wrlLdfPJNTlWnJPALeHKiNPRLD6kHS0-Mo_wotlddLRuKSfj19kxkazfBm-cuH8cJj76pFCuVKbQCWzC-ok7gK2-ZwO3nvEq9VnEQrG62bxkgFe8orEZIfm3Saw99sbUr7EwoHOvMircz4FMHm-ls5c8VqUpy81xn8TyYeZ6mTyZk0oJ0mVso_JbN5wU6hmKmxX-amhA2UTQ1f20Ic61JVskkmZjkmDmdBQBU2yribDqzD06_SH3I7n8KueHYNXOElHo-D1Gp2wU05zTdROMurfegGzTvCeR8v6lAaDygLXyG2quK6RF0LN_kwXat6JqRCAuyedHfzts0TEe1Yps8LY1LfyW4PtcFaZcUoLPjQwsDcM6yE0237I1qDMNhobp_qB_3V1xkenN7sPkLn47iRodN7-PoFMzG3xzffZvm4tVJBRcKuvxgTSCDf2GkJZSbz20RRv7kDZo",
          "X-tenant": "royalexpress",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> citiesList = responseData['data'];

          // Map and extract both City details and its corresponding State details
          return List<Map<String, dynamic>>.from(
            citiesList.map((city) {
              // Extract state accurately even if payload formats change slightly
              String extractedState = "Colombo"; // Default fallback state
              if (city["state_name"] != null) {
                extractedState = city["state_name"].toString();
              } else if (city["state"] != null &&
                  city["state"]["name"] != null) {
                extractedState = city["state"]["name"].toString();
              }

              return {
                "id": city["id"],
                "name": city["name"].toString(),
                "state_name": extractedState, // Parsed State auto-grouped here
              };
            }),
          );
        } else {
          throw Exception("Invalid data structure received from Curfox API");
        }
      } else if (response.statusCode == 401) {
        Get.snackbar(
          "Authentication Error",
          "Unauthorized access to Curfox API. Please check your token.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return [];
      } else {
        throw Exception(
          "Failed to load cities. Status Code: ${response.statusCode}",
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load cities: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return [];
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('sales_new') // modify this to match your collection name
        .doc(orderId)
        .update({'status': newStatus});
  }

  Future<List<Map<String, dynamic>>> fetchCurfoxCities({
    required String token,
    required String tenant,
  }) async {
    try {
      // API endpoint with filters bypassed to load the complete list
      final String url =
          "https://v1.api.curfox.com/api/public/merchant/city?noPaginationNoFilter=1";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization":
              "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYjFiNDk3OWM1YjEyNjEwNjUxMGFhZDMyMDQ0MzBiMWE0NWYyZTFiMzAzOTIzMTQ3ZjdjM2YyNWEzMGZkMDU0MzdhZWZjNmJiOTVkZWI2OTEiLCJpYXQiOjE3NzI3MzU4MzMuMjM2NDYzLCJuYmYiOjE3NzI3MzU4MzMuMjM2NDY1LCJleHAiOjQ5Mjg0MDk0MzMuMjIyMzE0LCJzdWIiOiI0Njc0Iiwic2NvcGVzIjpbXX0.jVbxQXE8AOGvYuWPQmDGA7VyYvPyw73AnyiCpGgdd0XD7GQCtMj5HLn0YNADASZwWOxRxK9J92OB0CW3KD_ZUtku7VYIbb8SYKOYDzBNrdt8EfiM7cKMf8vWaD22jnwi33_TEEdWzQxuI5HMqkq0AiKOm93lKgt94SGmeSl_xlWORKBENB4qvawCiQhRgluMnyxInC7mmbPGgHY1Mx_4IZ5nEXto3C6wrlLdfPJNTlWnJPALeHKiNPRLD6kHS0-Mo_wotlddLRuKSfj19kxkazfBm-cuH8cJj76pFCuVKbQCWzC-ok7gK2-ZwO3nvEq9VnEQrG62bxkgFe8orEZIfm3Saw99sbUr7EwoHOvMircz4FMHm-ls5c8VqUpy81xn8TyYeZ6mTyZk0oJ0mVso_JbN5wU6hmKmxX-amhA2UTQ1f20Ic61JVskkmZjkmDmdBQBU2yribDqzD06_SH3I7n8KueHYNXOElHo-D1Gp2wU05zTdROMurfegGzTvCeR8v6lAaDygLXyG2quK6RF0LN_kwXat6JqRCAuyedHfzts0TEe1Yps8LY1LfyW4PtcFaZcUoLPjQwsDcM6yE0237I1qDMNhobp_qB_3V1xkenN7sPkLn47iRodN7-PoFMzG3xzffZvm4tVJBRcKuvxgTSCDf2GkJZSbz20RRv7kDZo",
          "X-tenant": "royalexpress",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> citiesList = responseData['data'];

          // Map and extract both City details and its corresponding State details
          return List<Map<String, dynamic>>.from(
            citiesList.map((city) {
              // Extract state accurately even if payload formats change slightly
              String extractedState = "Colombo"; // Default fallback state
              if (city["state_name"] != null) {
                extractedState = city["state_name"].toString();
              } else if (city["state"] != null &&
                  city["state"]["name"] != null) {
                extractedState = city["state"]["name"].toString();
              }

              return {
                "id": city["id"],
                "name": city["name"].toString(),
                "state_name": extractedState, // Parsed State auto-grouped here
              };
            }),
          );
        } else {
          throw Exception("Invalid data structure received from Curfox API");
        }
      } else if (response.statusCode == 401) {
        Get.snackbar(
          "Authentication Error",
          "Curfox API token is invalid or expired.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        throw Exception("Unauthenticated Curfox API Request");
      } else {
        throw Exception("Failed to load cities: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "❌ Curfox API Error: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }
}
