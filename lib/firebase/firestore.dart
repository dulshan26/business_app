import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:http/http.dart' as http;
import 'package:own/api_handler/royal.dart';
import 'package:own/getxpac/sales/sales_model.dart';
import 'package:own/getxpac/sales_item/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final CollectionReference salesCollection = FirebaseFirestore.instance
      .collection('sales_new');

  // ---------------------------------------------------------------------------
  // Curfox defaults (so old calls like createCourierOrder(order) still work)
  // ---------------------------------------------------------------------------
  static String get _curfoxBase => CurfoxService.apiBase;
  static const String _defaultMerchantBusinessId = "4590";

  // Stream of all sales orders
  Stream<List<SalesModel>> getAllSalesOrders() {
    return salesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SalesModel.fromSnapshot(doc)).toList(),
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

      if (updates.containsKey('totalAmount')) {
        DocumentSnapshot oldDoc = await saleRef.get();
        if (oldDoc.exists) {
          var oldData = oldDoc.data() as Map<String, dynamic>;
          double oldAmount =
              double.tryParse(oldData['totalAmount'].toString()) ?? 0.0;
          double newAmount =
              double.tryParse(updates['totalAmount'].toString()) ?? 0.0;

          double amountDifference = newAmount - oldAmount;

          batch.set(globalSalesSummaryRef, {
            'total_revenue': FieldValue.increment(amountDifference),
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      batch.update(saleRef, updates);
      await batch.commit();
    } catch (e) {
      Get.snackbar("UPDATE ERROR", "Failed to update sales order: $e");
      throw Exception('Failed to update sales order: $e');
    }
  }

  // Delete - Delete sales order and restore stock
  Future<void> deleteSalesOrder(String orderId) async {
    try {
      final saleRef = _db.collection('sales_new').doc(orderId);
      final summaryRef = _db.collection('sales_summary').doc('overall');

      await _db.runTransaction((transaction) async {
        final saleSnapshot = await transaction.get(saleRef);
        final saleData = saleSnapshot.data();
        if (saleData == null) {
          throw StateError('Sales order not found.');
        }

        final rawItems = saleData['items'];
        if (rawItems is! Iterable) {
          throw StateError('Sales order has no valid item list.');
        }
        final items = rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final productRefs = <String, DocumentReference<Map<String, dynamic>>>{};
        for (final item in items) {
          final productId = (item['id'] ?? item['item_id'] ?? item['productId'])
              ?.toString();
          if (productId == null || productId.isEmpty) {
            throw StateError('A sales order item is missing its product ID.');
          }
          productRefs.putIfAbsent(
            productId,
            () => _db.collection('stock').doc(productId),
          );
        }

        final productSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final entry in productRefs.entries) {
          productSnapshots[entry.key] = await transaction.get(entry.value);
        }

        final updatedOptions = <String, List<Map<String, dynamic>>>{};
        final updatedBalances = <String, int>{};
        final stockTransactions = <(String, Map<String, dynamic>)>[];

        for (final item in items) {
          final productId = (item['id'] ?? item['item_id'] ?? item['productId'])
              .toString();
          final productData = productSnapshots[productId]?.data();
          if (productData == null) {
            throw StateError(
              'Cannot restore stock: product "${item['name'] ?? item['item_name'] ?? productId}" no longer exists.',
            );
          }

          final itemName = (item['name'] ?? item['item_name'] ?? 'Unknown Item')
              .toString();
          final rawQuantity = item['quantity'];
          final quantity = rawQuantity is num
              ? rawQuantity.toInt().abs()
              : int.tryParse(rawQuantity?.toString() ?? '')?.abs() ?? 0;
          if (quantity <= 0) continue;

          final selection = _readSalesItemOption(item);
          final optionName = selection.$1;
          final variantName = selection.$2;
          var variantBalanceAfter = 0;
          late int balanceAfter;

          if (optionName != null && variantName != null) {
            final options = updatedOptions.putIfAbsent(
              productId,
              () => _readStockOptions(productData, productId),
            );
            var variantFound = false;
            for (final option in options) {
              if (option['name']?.toString() != optionName) continue;
              final rawVariants = option['variants'];
              if (rawVariants is! Iterable) break;
              final variants = rawVariants
                  .whereType<Map>()
                  .map((variant) => Map<String, dynamic>.from(variant))
                  .toList();
              for (final variant in variants) {
                if (variant['name']?.toString() != variantName) continue;
                variantBalanceAfter = _readInt(variant['stock']) + quantity;
                variant['stock'] = variantBalanceAfter;
                variantFound = true;
                break;
              }
              option['variants'] = variants;
              break;
            }
            if (!variantFound) {
              throw StateError(
                'Cannot restore stock: $optionName / $variantName was not found for $itemName.',
              );
            }
            balanceAfter = options.fold<int>(0, (total, option) {
              final variants = option['variants'];
              if (variants is! Iterable) return total;
              return total +
                  variants.whereType<Map>().fold<int>(
                    0,
                    (subtotal, variant) =>
                        subtotal + _readInt(variant['stock']),
                  );
            });
            updatedBalances[productId] = balanceAfter;
          } else {
            final currentBalance = updatedBalances.putIfAbsent(
              productId,
              () => _readInt(productData['balance'] ?? productData['stock']),
            );
            balanceAfter = currentBalance + quantity;
            updatedBalances[productId] = balanceAfter;
          }

          stockTransactions.add((
            productId,
            {
              'quantity': quantity,
              'type': 'in',
              'note': 'Order Deleted / Cancelled (Order ID: $orderId)',
              'timestamp': FieldValue.serverTimestamp(),
              'item_name': itemName,
              'balance_after': balanceAfter,
              'option_name': optionName,
              'variant_name': variantName,
              'variant_balance_after': variantBalanceAfter,
            },
          ));
        }

        final totalAmount = _readDouble(saleData['totalAmount']);
        transaction.delete(saleRef);
        transaction.set(summaryRef, {
          'total_revenue': FieldValue.increment(-totalAmount),
          'total_orders': FieldValue.increment(-1),
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        for (final entry in updatedBalances.entries) {
          final update = <String, dynamic>{
            'balance': entry.value,
            'updated_at': FieldValue.serverTimestamp(),
          };
          final options = updatedOptions[entry.key];
          if (options != null) update['options'] = options;
          transaction.update(productRefs[entry.key]!, update);
        }

        for (final stockTransaction in stockTransactions) {
          final productRef = productRefs[stockTransaction.$1]!;
          final transactionRef = productRef.collection('transactions').doc();
          transaction.set(transactionRef, stockTransaction.$2);
        }
      });

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

  (String?, String?) _readSalesItemOption(Map<String, dynamic> item) {
    final directOptionName = item['option_name'] ?? item['optionName'];
    final directVariantName = item['variant_name'] ?? item['variantName'];
    if (directOptionName != null || directVariantName != null) {
      if (directOptionName == null || directVariantName == null) {
        throw StateError('The sales item has incomplete variant details.');
      }
      return (directOptionName.toString(), directVariantName.toString());
    }

    final attributes = item['selectedAttributes'] ?? item['attributes'];
    if (attributes is Map && attributes.length == 1) {
      final entry = attributes.entries.first;
      return (entry.key.toString(), entry.value.toString());
    }
    if (attributes is Map && attributes.isNotEmpty) {
      throw StateError(
        'Cannot restore stock for an order item with multiple selected option values.',
      );
    }
    return (null, null);
  }

  List<Map<String, dynamic>> _readStockOptions(
    Map<String, dynamic> productData,
    String productId,
  ) {
    return ItemModel.fromMap(
      productData,
      id: productId,
    ).options.map((option) => option.toMap()).toList();
  }

  int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Dialog to trigger order deletion
  void deleteOrderShow(String orderId, BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await deleteSalesOrder(orderId);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> syncCourierStatus(String orderId, String waybill) async {
    try {
      String? status = await CurfoxService().getCurrentStatus(waybill);
      if (status != null) {
        await salesCollection.doc(orderId).update({
          "courierStatus": status,
          "courierUpdated": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Error syncing status: $e");
    }
  }

  Future<void> syncAllCourierStatuses() async {
    try {
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

      Get.snackbar(
        "Syncing...",
        "Updating all courier statuses in background...",
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
      );

      List<Future<void>> syncTasks = querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        String? trackingNumber = data['trackingNumber'];

        if (trackingNumber != null && trackingNumber.isNotEmpty) {
          try {
            String? status = await CurfoxService().getCurrentStatus(
              trackingNumber,
            );
            if (status != null) {
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
          }
        }
      }).toList();

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

  // Create single courier order.
  // token / tenant / merchantBusinessId are OPTIONAL now, so the old call
  //   createCourierOrder(order)
  // still works, and the new call with named params works too.
  Future<void> createCourierOrder(
    SalesModel order, {
    String? token,
    String? tenant,
    String? merchantBusinessId,
  }) async {
    try {
      final useToken = token ?? CurfoxService.authToken;
      final useTenant = tenant ?? CurfoxService.tenantId;
      final useMerchantId =
          merchantBusinessId ?? _defaultMerchantBusinessId;
      final docSnapshot = await salesCollection.doc(order.id).get();

      if (docSnapshot.exists) {
        final dbData = docSnapshot.data() as Map<String, dynamic>?;
        if (dbData != null &&
            dbData['trackingNumber'] != null &&
            dbData['trackingNumber'].toString().isNotEmpty) {
          Get.snackbar(
            "Already Created",
            "Courier order already exists. Tracking Number: ${dbData['trackingNumber']}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.amber[800],
            colorText: const Color.fromARGB(255, 73, 70, 70),
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(12),
          );
          return;
        }
      }

      final int safeCodAmount = (order.totalAmount).round();
      final String targetCity = order.destinationCity ?? "Colombo 02";
      final String targetState = order.destinationState ?? "Colombo";

      final response = await http.post(
        Uri.parse("$_curfoxBase/order/single"),
        headers: CurfoxService.headers(token: useToken, tenant: useTenant),
        body: jsonEncode({
          "general_data": {
            "merchant_business_id": useMerchantId,
            "origin_city_name": "Kotte",
            "origin_state_name": "Colombo",
          },
          "order_data": [
            {
              "waybill": "", // empty = auto-generate
              "order_no": order.id.toString(),
              "customer_name": order.customerName ?? "Customer",
              "customer_address":
                  order.customerAddress ?? "No Address Provided",
              "customer_phone": order.customerPhone,
              "customer_secondary_phone": order.custonerPhone2 ?? "",
              "destination_city_name": targetCity, // name, not ID
              "destination_state_name": targetState,
              "cod": safeCodAmount, // integer
              "weight": 1.0,
              "description": "if not Contact customer call me 0779833106",
              "remark": "Please handle with care",
            },
          ],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = response.body.trim();
        String? generatedWaybill;

        // Response body may be empty per the Curfox docs
        if (responseBody.isNotEmpty) {
          try {
            final responseData = jsonDecode(responseBody);
            if (responseData is Map &&
                responseData['data'] is List &&
                (responseData['data'] as List).isNotEmpty) {
              generatedWaybill = responseData['data'][0].toString();
            }
          } catch (e) {
            Get.snackbar(
              "Response Error",
              "Courier API returned an invalid response: $e",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red[900],
              colorText: Colors.white,
              duration: const Duration(seconds: 8),
            );
          }
        }

        await salesCollection.doc(order.id).update({
          "trackingNumber": generatedWaybill ?? "",
          "courierStatus": "Order Created",
          "courierPartner": "Royal Courier",
          "courierCost": 425.0,
          "status": "Sent",
          "courierUpdated": FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          "Success",
          generatedWaybill != null
              ? "Courier order created! Waybill: $generatedWaybill"
              : "Courier order created. Waybill number needs verification.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[800],
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        throw Exception(
          "Curfox API Error (${response.statusCode}): ${response.body}",
        );
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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await salesCollection.doc(orderId).update({'status': newStatus});
  }

  // Single reusable method for fetching Curfox cities
  Future<List<Map<String, dynamic>>> fetchCurfoxCities({
    required String token,
    required String tenant,
    bool noPaginationNoFilter = false,
  }) async {
    try {
      final String endpoint = noPaginationNoFilter
          ? "city?noPaginationNoFilter=1"
          : "city?noPagination=1";

      final response = await http.get(
        Uri.parse("$_curfoxBase/$endpoint"),
        headers: CurfoxService.headers(token: token, tenant: tenant),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data') && responseData['data'] is List) {
          List<dynamic> citiesList = responseData['data'];

          return List<Map<String, dynamic>>.from(
            citiesList.map((city) {
              String extractedState = "Colombo";
              if (city["state_name"] != null) {
                extractedState = city["state_name"].toString();
              } else if (city["state"] != null &&
                  city["state"]["name"] != null) {
                extractedState = city["state"]["name"].toString();
              }

              return {
                "id": city["id"],
                "name": city["name"].toString(),
                "state_name": extractedState,
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

  // Kept so existing callers of loadCurfoxCities() don't break.
  // Same behaviour as before: uses ?noPagination=1 and returns [] on error.
  Future<List<Map<String, dynamic>>> loadCurfoxCities({
    required String token,
    required String tenant,
  }) async {
    try {
      return await fetchCurfoxCities(token: token, tenant: tenant);
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> cachedCurfoxCities = [];

  // Same as before: cache uses the "noPaginationNoFilter" endpoint
  Future<List<Map<String, dynamic>>> getCachedCities({
    required String token,
    required String tenant,
  }) async {
    if (cachedCurfoxCities.isNotEmpty) {
      return cachedCurfoxCities;
    }
    final cities = await fetchCurfoxCities(
      token: token,
      tenant: tenant,
      noPaginationNoFilter: true,
    );
    cachedCurfoxCities = cities;
    return cities;
  }
}
