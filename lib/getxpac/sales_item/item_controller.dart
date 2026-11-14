import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/sales_item/item_model.dart';

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
  Future<bool> updateStock({
    required String productId,
    required String itemName,
    required int quantity,
    required String type,
    String note = "",
    String? optionName,
    String? variantName,
  }) async {
    try {
      if (quantity <= 0 || (type != 'in' && type != 'out')) {
        throw ArgumentError('Invalid stock transaction.');
      }

      final productRef = _db.collection('stock').doc(productId);
      DocumentReference transRef = productRef.collection('transactions').doc();
      await _db.runTransaction((transaction) async {
        final productSnapshot = await transaction.get(productRef);
        final productData = productSnapshot.data();
        if (productData == null) {
          throw StateError('The inventory item no longer exists.');
        }

        final currentBalance = _asInt(
          productData['balance'] ?? productData['stock'],
        );
        var newBalance = type == 'out'
            ? currentBalance - quantity
            : currentBalance + quantity;
        var variantBalanceAfter = newBalance;
        if (optionName != null || variantName != null) {
          if (optionName == null || variantName == null) {
            throw ArgumentError('Both option and variant are required.');
          }
          final item = ItemModel.fromMap(productData, id: productId);
          if (item.options.isEmpty) {
            throw StateError('This item has no variants to update.');
          }
          final options = item.options.map((option) => option.toMap()).toList();
          var optionFound = false;
          var variantFound = false;
          for (final option in options) {
            if (option['name']?.toString() != optionName) continue;
            optionFound = true;
            final rawVariants = option['variants'];
            if (rawVariants is! Iterable) break;
            final variants = rawVariants
                .whereType<Map>()
                .map((variant) => Map<String, dynamic>.from(variant))
                .toList();
            for (final variant in variants) {
              if (variant['name']?.toString() != variantName) continue;
              variantFound = true;
              final currentVariantBalance = _asInt(variant['stock']);
              if (type == 'out' && quantity > currentVariantBalance) {
                throw StateError('Not enough stock for $variantName.');
              }
              variantBalanceAfter = type == 'out'
                  ? currentVariantBalance - quantity
                  : currentVariantBalance + quantity;
              variant['stock'] = variantBalanceAfter;
              break;
            }
            option['variants'] = variants;
            break;
          }
          if (!optionFound || !variantFound) {
            throw StateError('The selected option variant was not found.');
          }

          newBalance = options.fold<int>(0, (total, option) {
            final variants = option['variants'];
            if (variants is! Iterable) return total;
            return total +
                variants.whereType<Map>().fold<int>(
                  0,
                  (optionTotal, variant) =>
                      optionTotal + _asInt(variant['stock']),
                );
          });
          transaction.update(productRef, {
            'options': options,
            'balance': newBalance,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          if (type == 'out' && quantity > currentBalance) {
            throw StateError('Not enough stock available.');
          }
          transaction.update(productRef, {
            'balance': newBalance,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        final transactionData = <String, dynamic>{
          'quantity': quantity,
          'balance_after': newBalance,
          'type': type,
          'note': note,
          'timestamp': FieldValue.serverTimestamp(),
          'item_name': itemName,
        };
        if (optionName != null && variantName != null) {
          transactionData.addAll({
            'option_name': optionName,
            'variant_name': variantName,
            'variant_balance_after': variantBalanceAfter,
          });
        }
        transaction.set(transRef, transactionData);
      });

      Get.snackbar(
        "Success",
        "Stock updated successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update stock: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // ➕ Create - අලුත් Item එකක් Inventory එකට එකතු කිරීම
  Future<bool> addItem({
    required String name,
    required double price,
    required int initialStock,
    required String mainImage,
    required List<String> images,
    required String description,
    required String category,
    required bool isActive,
    required List<StockOptionModel> options,
    required List<String> descriptionImages,
  }) async {
    try {
      isLoading.value = true;

      DocumentReference productRef = _db.collection('stock').doc();
      DocumentReference transRef = productRef.collection('transactions').doc();

      WriteBatch batch = _db.batch();

      batch.set(productRef, {
        'item_name': name,
        'description': description,
        'description_images': descriptionImages,
        'category': category,
        'price': price,
        'balance': initialStock,
        'main_image': mainImage,
        'images': images,
        'isActive': isActive,
        'options': options.map((option) => option.toMap()).toList(),
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
      return true;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to add item: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
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
  Future<bool> editStockItem({
    required String productId,
    required String name,
    required String description,
    required String category,
    required double price,
    required int balance,
    required String mainImage,
    required List<String> images,
    required bool isActive,
    required List<StockOptionModel> options,
    required List<String> descriptionImages,
  }) async {
    try {
      isLoading.value = true;
      await _db.collection('stock').doc(productId).update({
        'item_name': name,
        'description': description,
        'description_images': descriptionImages,
        'category': category,
        'price': price,
        'balance': balance,
        'main_image': mainImage,
        'images': images,
        'isActive': isActive,
        'options': options.map((option) => option.toMap()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      Get.snackbar("Success", "Product updated successfully");
      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 🌟 ඔයාගේ StockListController එක ඇතුළේ තියෙන variables මේ විදිහට update කරන්න:
  var selectedCategory =
      "".obs; // මුලින්ම කිසිම category එකක් select වෙලා නෑ (Show All)

  void changeCategory(String category) {
    if (category.toLowerCase() == 'all' || selectedCategory.value == category) {
      // 🔄 දෙවැනි පාර ක්ලික් කළොත් deselect කරලා clear කරනවා (Show All)
      selectedCategory.value = "";
    } else {
      // 🎯 පළමු පාර ක්ලික් කළොත් ඒ category එක select කරනවා
      selectedCategory.value = category;
    }
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
