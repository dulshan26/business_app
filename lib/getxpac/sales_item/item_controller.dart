import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockHistoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // සජීවී දත්ත ලැයිස්තුව තියාගන්නා RxVariable එකක්
  final RxList<Map<String, dynamic>> transactions =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  final String productId;
  StockHistoryController({required this.productId});

  @override
  void onInit() {
    super.onInit();
    fetchTransactionHistory();
  }

  void fetchTransactionHistory() {
    // 💡 ඔයා හදපු Sub-collection Path එකටම Stream එකක් සම්බන්ධ කිරීම
    _db
        .collection('stock')
        .doc(productId)
        .collection('transactions')
        .orderBy('timestamp', descending: true) // අලුත්ම ඒවා උඩටම එන්න
        .snapshots()
        .listen(
          (snapshot) {
            transactions.value = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id; // Document ID එකත් දත්ත වලට එකතු කරගන්නවා
              return data;
            }).toList();

            isLoading.value = false;
          },
          onError: (error) {
            SnackBar(content: Text("Error fetching transactions: $error"));
            isLoading.value = false;
          },
        );
  }
}

class StockListController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 📦 සියලුම බඩු ලැයිස්තුව තියාගන්නා RxList එකක්
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts();
  }

  void fetchAllProducts() {
    // 💡 ඔයාගේ ප්‍රධාන 'stock' collection එකට Stream එකක් සම්බන්ධ කිරීම
    _db
        .collection('stock')
        .snapshots()
        .listen(
          (snapshot) {
            products.value = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc
                  .id; // 🔥 Firestore Document ID එක (ykSGfVFFQaZSZzDZJrIe...)
              return data;
            }).toList();

            isLoading.value = false;
          },
          onError: (error) {
            SnackBar(content: Text("Error fetching products: $error"));
            isLoading.value = false;
          },
        );
  }

  Future<void> updateStock({
    required String productId,
    required String itemName,
    required int quantity,
    required int currentBalance,
    required String type,
    String note = "",
  }) async {
    try {
      // අලුත් Balance එක හදනවා
      int newBalance = type == "out"
          ? currentBalance - quantity
          : currentBalance + quantity;

      WriteBatch batch = _db.batch();
      DocumentReference productRef = _db.collection('stock').doc(productId);
      DocumentReference transRef = productRef.collection('transactions').doc();

      // 1. Sub-collection එකට Transaction එක දානවා
      batch.set(transRef, {
        'quantity': quantity,
        'balance_after': newBalance,
        'type': type,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
        'item_name': itemName,
      });

      // 2. ප්‍රධාන Product Document එකේ Balance එක Update කරනවා
      batch.update(productRef, {
        'balance': newBalance,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      Get.snackbar(
        "Success",
        "Stock updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update stock: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
