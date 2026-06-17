import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:own/getxpac/front_page.dart';

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
        return {
          'id': doc
              .id, // 🌟 FIX: 'docId' වෙනුවට කෙලින්ම 'id' කියලා ගත්තා ලේසි වෙන්න
          'item_name': d['item_name'] ?? 'No Name',
          'description': d['description'] ?? '',
          'balance': d['balance'] ?? 0,
          'price': (d['price'] ?? 0).toDouble(),
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
  void addItemToCart(Map<String, dynamic> stock) {
    int index = selectedItems.indexWhere(
      (item) => item['id'] == stock['id'],
    ); // 🌟 FIX: ID එකෙන් check කරන්නේ

    if (index >= 0) {
      increaseQty(index);
    } else {
      selectedItems.add({
        'id': stock['id'], // 🌟 Document ID එකම යනවා
        'name': stock['item_name'],
        'quantity': 1,
        'price': stock['price'],
      });
      calculateTotal();
    }
  }

  void increaseQty(int index) {
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
    double finalAmount =
        double.tryParse(amountController.text.trim()) ?? totalAmount.value;
    if (selectedItems.isEmpty) {
      Get.snackbar("Error", "No items added to sale");
      return;
    }

    try {
      isLoading.value = true;
      WriteBatch batch = _db.batch();
      DocumentReference saleRef = _db.collection('sales_new').doc();

      SalesModel newSale = SalesModel(
        customerPhone: phone,
        items: selectedItems,
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

      batch.set(saleRef, newSale.toMap());

      DocumentReference globalSalesSummaryRef = _db
          .collection('sales_summary')
          .doc('overall');

      // 5. 📉 Summary එකෙන් මුදල් සහ ඕඩර් ගණන අඩු කිරීම
      batch.set(globalSalesSummaryRef, {
        'total_revenue': FieldValue.increment(totalAmount.value),
        'total_orders': FieldValue.increment(1),
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 🔄 Items හරහා ලූප් එක
      for (var item in selectedItems) {
        String productId =
            item['id']; // 🌟 FIX: දැන් මෙතනට 100% ක්ම නිවැරදි Firestore Document ID එක ලැබෙනවා
        String itemName = item['name'] ?? 'Unknown Item';
        int quantitySold = int.tryParse(item['quantity'].toString()) ?? 1;

        DocumentReference productRef = _db.collection('stock').doc(productId);

        // Stock එක අඩු කිරීම
        batch.update(productRef, {
          'balance': FieldValue.increment(-quantitySold),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Sub-collection එකට Transaction එක දැමීම
        DocumentReference transRef = productRef
            .collection('transactions')
            .doc();
        batch.set(transRef, {
          'quantity': -quantitySold,
          'type': 'out',
          'note': 'Sales Transaction (Order: ${saleRef.id})',
          'timestamp': FieldValue.serverTimestamp(),
          'item_name': itemName,
        });
      }

      await batch.commit();
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
}
