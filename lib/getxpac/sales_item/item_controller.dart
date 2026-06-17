import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ==========================================
// 📜 STOCK HISTORY CONTROLLER
// ==========================================
class StockHistoryController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    _db
        .collection('stock')
        .doc(productId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            transactions.value = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();

            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar(
              "Error",
              "Error fetching transactions: $error",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          },
        );
  }
}

// ==========================================
// 📦 STOCK LIST CONTROLLER
// ==========================================
class StockListController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🌟 Search එක නිවැරදිව වැඩ කරන්න පාවිච්චි කරන ප්‍රධාන ලිස්ට් දෙක
  final RxList<Map<String, dynamic>> allProducts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> products =
      <Map<String, dynamic>>[].obs; // UI එක ලිසන් කරන්නේ මේකටයි
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts();
  }

  void fetchAllProducts() {
    _db
        .collection('stock')
        .snapshots()
        .listen(
          (snapshot) {
            // 🌟 FIX: local variable නම 'fetchedItems' කියලා වෙනස් කළා පැටලෙන්නේ නැති වෙන්න
            var fetchedItems = snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id; // Firestore Document ID එක ගන්නවා
              return data;
            }).toList();

            // 🌟 FIX: variables දෙකටම පිළිවෙලට දත්ත දානවා
            allProducts.assignAll(fetchedItems);
            products.assignAll(fetchedItems);

            isLoading.value = false;
          },
          onError: (error) {
            isLoading.value = false;
            Get.snackbar(
              "Error",
              "Error fetching products: $error",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          },
        );
  }

  // 🔍 සර්ච් කරන්න පාවිච්චි කරන නිවැරදි Function එක
  void searchProducts(String query) {
    if (query.isEmpty) {
      products.assignAll(allProducts); // හිස් නම් සේරම ආපහු පෙන්වනවා
    } else {
      var filtered = allProducts
          .where(
            (product) =>
                product['item_name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                product['id'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
          ) // ID සහ Name දෙකෙන්ම සර්ච් කරන්න පුළුවන්
          .toList();
      products.assignAll(filtered);
    }
  }

  // 🔄 Stock In / Stock Out වෙනස් කරන Function එක
  Future<void> updateStock({
    required String productId,
    required String itemName,
    required int quantity,
    required int currentBalance,
    required String type,
    String note = "",
  }) async {
    try {
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
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update stock: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ➕ Create - අලුත් Item එකක් Inventory එකට එකතු කිරීම
  Future<void> addItem({
    required String name,
    required double price,
    required int initialStock,
  }) async {
    try {
      isLoading.value = true;

      DocumentReference productRef = _db.collection('stock').doc();
      DocumentReference transRef = productRef.collection('transactions').doc();

      WriteBatch batch = _db.batch();

      batch.set(productRef, {
        'item_name': name,
        'price': price,
        'balance': initialStock,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      batch.set(transRef, {
        'quantity': initialStock,
        'balance_after': initialStock,
        'type': 'in',
        'note': 'Initial stock registration',
        'timestamp': FieldValue.serverTimestamp(),
        'item_name': name,
      });

      await batch.commit();

      Get.snackbar(
        "Success",
        "$name added to inventory successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to add item: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ❌ Delete - Item එකක් සම්පූර්ණයෙන්ම සිස්ටම් එකෙන් ඉවත් කිරීම
  Future<void> removeItem(String productId) async {
    try {
      await _db.collection('stock').doc(productId).delete();

      Get.snackbar(
        "Deleted",
        "Item removed successfully from inventory!",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to remove item: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ✏️ Edit - Item එකක තොරතුරු සහ Transaction History එක Batch Update එකකින් සිදු කිරීම
  Future<void> editStockItem({
    required String productId,
    required String name,
    required String description,
    required String category,
    required double price,
    required int balance,
    required List<String> images,
    required bool isActive,
  }) async {
    try {
      await _db.collection('stock').doc(productId).update({
        'item_name': name,
        'description': description,
        'category': category,
        'price': price,
        'balance': balance,
        'images': images,
        'isActive': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Product updated successfully");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
