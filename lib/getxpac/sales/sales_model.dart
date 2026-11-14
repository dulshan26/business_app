import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:own/getxpac/front_page.dart';
import 'package:own/getxpac/sales_item/item_model.dart';

class SalesModel {
  final String? id;
  final String customerPhone;
  final String? custonerPhone2;
  final String? customerName; //
  final String? customerAddress; //
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final DateTime createdAt;
  final String status;
  final String? note;
  final bool smsSent;
  final String? destinationCity;
  final String? destinationState;
  final String? courierStatus;
  final String? courierPatner;
  final String? trackingNumber;
  final double? courierCost;
  final Timestamp? courierUpdatedAt;

  SalesModel({
    this.id,
    required this.customerPhone,
    this.customerName, // ➕
    this.customerAddress, // ➕
    this.destinationCity, // ➕
    this.destinationState, // ➕
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'Pending',
    this.note,
    required this.smsSent,
    this.courierStatus,
    this.courierPatner,
    this.courierCost,
    this.custonerPhone2,
    this.trackingNumber,
    this.courierUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerPhone': customerPhone,
      'customerName': customerName, // ➕ Firebase එකට යන්න
      'customerAddress': customerAddress, // ➕ Firebase එකට යන්න
      'destinationCity': destinationCity, // ➕ Firebase එකට යන්න
      'destinationState': destinationState, // ➕ Firebase එකට යන්න
      'items': items,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'status': status,
      'note': note,
      'smsSent': smsSent,
      'courierStatus': courierStatus,
      'courierPatner': courierPatner,
      'courierCost': courierCost,
      'custonerPhone2': custonerPhone2,
      'trackingNumber': trackingNumber,
      'courierUpdatedAt': courierUpdatedAt,
    };
  }

  factory SalesModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return SalesModel(
      id: snap.id,
      customerPhone: data['customerPhone'] ?? '',
      customerName: data['customerName'] ?? 'No Name', // ➕
      customerAddress: data['customerAddress'] ?? 'No Address', // ➕
      destinationCity: data['destinationCity'] ?? 'No City', // ➕
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'Pending',
      note: data['note'],
      smsSent: data['smsSent'] ?? false,
      courierStatus: data['courierStatus'],
      courierPatner: data['courierPatner'],
      courierCost: (data['courierCost'] ?? 0).toDouble(),
      custonerPhone2: data['custonerPhone2'],
      trackingNumber: data['trackingNumber'],
      courierUpdatedAt: data['courierUpdatedAt'],
      destinationState: data['destinationState'], // ➕ Firebase එකට යන්න
    );
  }
}

class SalesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var allStockItems = <Map<String, dynamic>>[].obs;
  var filteredStockItems = <Map<String, dynamic>>[].obs;
  var selectedItems = <Map<String, dynamic>>[].obs;
  var totalAmount = 0.0.obs;

  final amountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchStockItems();
  }

  // 📦 1. Stock Items හරියටම කියවා ගැනීම
  Future<void> fetchStockItems() async {
    try {
      isLoading.value = true;
      // 🌟 FIX: 'item_id' වෙනුවට 'item_name' එකෙන් order කළා. එතකොට හැම item එකක්ම අනිවාර්යයෙන්ම වැටෙනවා.
      final snap = await _db.collection('stock').orderBy('item_name').get();

      var items = snap.docs.map((doc) {
        final d = doc.data();
        final item = ItemModel.fromMap(d, id: doc.id);
        return {
          'id': doc
              .id, // 🌟 FIX: 'docId' වෙනුවට කෙලින්ම 'id' කියලා ගත්තා ලේසි වෙන්න
          'item_name': d['item_name'] ?? 'No Name',
          'description': d['description'] ?? '',
          'balance': d['balance'] ?? 0,
          'price': (d['price'] ?? 0).toDouble(),
          'options': item.options.map((option) => option.toMap()).toList(),
        };
      }).toList();

      allStockItems.assignAll(items);
      filteredStockItems.assignAll(items);
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch stock items: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchStock(String query) {
    if (query.isEmpty) {
      filteredStockItems.assignAll(allStockItems);
    } else {
      var result = allStockItems
          .where(
            (item) => item['item_name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
      filteredStockItems.assignAll(result);
    }
  }

  // 🛒 2. Cart එකට Item එකතු කිරීම
  void addItemToCart(
    Map<String, dynamic> stock, {
    String? optionName,
    String? variantName,
    double? unitPrice,
    int? availableStock,
  }) {
    final id = stock['id'].toString();
    final cartKey = '$id::${optionName ?? ''}::${variantName ?? ''}';
    final index = selectedItems.indexWhere(
      (item) => item['cartKey'] == cartKey,
    );

    if (index >= 0) {
      increaseQty(index);
    } else {
      selectedItems.add({
        'cartKey': cartKey,
        'id': id,
        'name': stock['item_name'],
        'quantity': 1,
        'price': unitPrice ?? _asDouble(stock['price']),
        'optionName': optionName,
        'variantName': variantName,
        'availableStock': availableStock ?? _asInt(stock['balance']),
      });
      calculateTotal();
    }
  }

  void increaseQty(int index) {
    if (_asInt(selectedItems[index]['quantity']) >=
        _asInt(selectedItems[index]['availableStock'])) {
      Get.snackbar("Stock limit", "There is no more stock for this selection.");
      return;
    }
    selectedItems[index]['quantity'] += 1;
    selectedItems.refresh(); // GetX වලට ලිස්ට් එක update වුන බව කියන්න
    calculateTotal();
  }

  void decreaseQty(int index) {
    if (selectedItems[index]['quantity'] > 1) {
      selectedItems[index]['quantity']--;
    } else {
      selectedItems.removeAt(index);
    }
    selectedItems.refresh();
    calculateTotal();
  }

  void calculateTotal() {
    totalAmount.value = selectedItems.fold(
      0.0,
      // ignore: avoid_types_as_parameter_names
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
    amountController.text = totalAmount.value.toStringAsFixed(2);
  }

  // 💾 3. සේල් එක සේව් කිරීම සහ Stock එක අඩු කිරීම
  //this is where sales orders happend
  Future<void> saveSalesTransaction({
    required String phone,
    String? name,
    String? address,
    String? phone2,
  }) async {
    final double finalAmount =
        double.tryParse(amountController.text.trim()) ?? totalAmount.value;
    if (selectedItems.isEmpty) {
      Get.snackbar("Error", "No items added to sale");
      return;
    }

    try {
      isLoading.value = true;
      final saleRef = _db.collection('sales_new').doc();
      final summaryRef = _db.collection('sales_summary').doc('overall');
      final productRefs = <String, DocumentReference<Map<String, dynamic>>>{};
      for (final item in selectedItems) {
        final productId = item['id'].toString();
        productRefs.putIfAbsent(
          productId,
          () => _db.collection('stock').doc(productId),
        );
      }
      final saleItems = selectedItems
          .map(
            (item) => <String, dynamic>{
              'id': item['id'].toString(),
              'name': item['name'].toString(),
              'quantity': _asInt(item['quantity']),
              'price': _asDouble(item['price']),
              'optionName': item['optionName'],
              'variantName': item['variantName'],
            },
          )
          .toList();

      SalesModel newSale = SalesModel(
        customerPhone: phone,
        items: saleItems,
        totalAmount: finalAmount,
        createdAt: DateTime.now(),
        note: null,
        status: 'Pending',
        smsSent: false,
        courierStatus: null,
        courierPatner: null,
        courierCost: null,
        customerName: name ?? '',
        customerAddress: address ?? '',
        custonerPhone2: phone2 ?? '',
        trackingNumber: null,
        courierUpdatedAt: null,
        destinationCity: null,
      );

      await _db.runTransaction((transaction) async {
        final snapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final entry in productRefs.entries) {
          snapshots[entry.key] = await transaction.get(entry.value);
        }

        final updatedOptionsByProduct = <String, List<Map<String, dynamic>>>{};
        final updatedBalances = <String, int>{};
        transaction.set(saleRef, newSale.toMap());
        transaction.set(summaryRef, {
          'total_revenue': FieldValue.increment(finalAmount),
          'total_orders': FieldValue.increment(1),
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        for (final item in selectedItems) {
          final productId = item['id'].toString();
          final productRef = productRefs[productId]!;
          final productData = snapshots[productId]?.data();
          if (productData == null) {
            throw StateError('Item "${item['name']}" is no longer available.');
          }

          final quantity = _asInt(item['quantity']);
          final optionName = item['optionName']?.toString();
          final variantName = item['variantName']?.toString();
          var variantBalanceAfter = 0;
          late int balanceAfter;

          if (optionName != null && variantName != null) {
            final options = updatedOptionsByProduct.putIfAbsent(
              productId,
              () => ItemModel.fromMap(
                productData,
                id: productId,
              ).options.map((option) => option.toMap()).toList(),
            );
            var matched = false;
            for (final option in options) {
              if (option['name'] != optionName) continue;
              final rawVariants = option['variants'];
              if (rawVariants is! Iterable) break;
              final variants = rawVariants
                  .whereType<Map>()
                  .map((variant) => Map<String, dynamic>.from(variant))
                  .toList();
              for (final variant in variants) {
                if (variant['name'] != variantName) continue;
                final currentStock = _asInt(variant['stock']);
                if (quantity > currentStock) {
                  throw StateError(
                    'Not enough stock for ${item['name']} ($variantName).',
                  );
                }
                variantBalanceAfter = currentStock - quantity;
                variant['stock'] = variantBalanceAfter;
                matched = true;
                break;
              }
              option['variants'] = variants;
              break;
            }
            if (!matched) {
              throw StateError(
                'The selected option for ${item['name']} is no longer available.',
              );
            }
            balanceAfter = options.fold<int>(0, (total, option) {
              final variants = option['variants'];
              if (variants is! Iterable) return total;
              return total +
                  variants.whereType<Map>().fold<int>(
                    0,
                    (subtotal, variant) =>
                        subtotal + _asInt(variant['stock']),
                  );
            });
            updatedBalances[productId] = balanceAfter;
          } else {
            final currentStock = updatedBalances.putIfAbsent(
              productId,
              () => _asInt(productData['balance'] ?? productData['stock']),
            );
            if (quantity > currentStock) {
              throw StateError('Not enough stock for ${item['name']}.');
            }
            balanceAfter = currentStock - quantity;
            updatedBalances[productId] = balanceAfter;
          }

          final transRef = productRef.collection('transactions').doc();
          transaction.set(transRef, {
            'quantity': quantity,
            'type': 'out',
            'note': 'Sales Transaction (Order: ${saleRef.id})',
            'timestamp': FieldValue.serverTimestamp(),
            'item_name': item['name'],
            'balance_after': balanceAfter,
            'option_name': optionName,
            'variant_name': variantName,
            'variant_balance_after': variantBalanceAfter,
          });
        }

        for (final entry in updatedBalances.entries) {
          final update = <String, dynamic>{
            'balance': entry.value,
            'updated_at': FieldValue.serverTimestamp(),
          };
          final options = updatedOptionsByProduct[entry.key];
          if (options != null) update['options'] = options;
          transaction.update(productRefs[entry.key]!, update);
        }
      });
      Get.snackbar(
        "Success",
        "Sale recorded and stock updated successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      selectedItems.clear();
      amountController.clear();
      Get.offAll(() => const FrontPage());
    } catch (e) {
      Get.snackbar(
        "Error",
        "Sale failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> placeWebOrder({
    required String phone,
    required String name,
    required String address,
    required String phone2,
  }) async {
    if (selectedItems.isEmpty) return false;

    try {
      isLoading.value = true;
      WriteBatch batch = _db.batch();
      DocumentReference saleRef = _db.collection('sales_new').doc();

      // 🛒 Firebase එක බ්ලොක් නොවන ලෙස පිරිසිදු Maps ලැයිස්තුවක් සාදා ගැනීම
      List<Map<String, dynamic>> structuredItems = selectedItems.map((item) {
        return {
          'id': item['id'].toString(),
          'name': item['name'].toString(),
          'quantity': int.tryParse(item['quantity'].toString()) ?? 1,
          'price': double.tryParse(item['price'].toString()) ?? 0.0,
        };
      }).toList();

      SalesModel newSale = SalesModel(
        customerPhone: phone,
        items: structuredItems, // 🎯 පිරිසිදු කරන ලද ලිස්ට් එක
        totalAmount: totalAmount.value,
        createdAt: DateTime.now(),
        status: 'Web Sales',
        smsSent: false,
        courierStatus: 'Pending',
        customerName: name,
        customerAddress: address,
        custonerPhone2: phone2,
      );

      batch.set(saleRef, newSale.toMap());

      // Summary Update
      DocumentReference globalSummaryRef = _db
          .collection('sales_summary')
          .doc('overall');
      batch.set(globalSummaryRef, {
        'total_revenue': FieldValue.increment(totalAmount.value),
        'total_orders': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Stock Update
      for (var item in structuredItems) {
        String productId = item['id'];
        String itemName = item['name'];
        int quantitySold = item['quantity'];

        DocumentReference productRef = _db.collection('stock').doc(productId);
        batch.update(productRef, {
          'balance': FieldValue.increment(-quantitySold),
          'updated_at': FieldValue.serverTimestamp(),
        });

        DocumentReference transRef = productRef
            .collection('transactions')
            .doc();
        batch.set(transRef, {
          'quantity': -quantitySold,
          'type': 'out',
          'note': 'Web Sales Transaction (Order: ${saleRef.id})',
          'timestamp': FieldValue.serverTimestamp(),
          'item_name': itemName,
        });
      }

      await batch.commit();
      selectedItems.clear();
      calculateTotal();
      return true;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Web order failed: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
