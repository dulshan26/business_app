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
    );
  }
}

class SalesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var isLoading = false.obs;

  //stock eke. tiyana badu tika tiya ganne eka stock collection ekata query ekak dila. eka fetch karala allStockItems list ekata danna one. e list eka filteredStockItems list ekata copy karala. search bar ekak thiyenawanam, search bar eke text change wenakota filteredStockItems list eka update wenna one. search bar eke text eka item_name field ekata match wenna one. match una items tika filteredStockItems list ekata danna one. search bar eke text eka clear karala nam, filteredStockItems list eka allStockItems list ekata copy karala danna one.
  var allStockItems = <Map<String, dynamic>>[].obs; // All items from stock
  var filteredStockItems =
      <Map<String, dynamic>>[].obs; // Filtered items based on search

  //local card eka,, toora gatta badu tika
  var selectedItems = <Map<String, dynamic>>[].obs; // Local cart
  var totalAmount = 0.0.obs;

  final amountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchStockItems();
    // Any initialization if needed
  } //page eka open weddima badu tika load kara ganne oni

  Future<void> fetchStockItems() async {
    try {
      isLoading.value = true;
      final snap = await _db.collection('stock').orderBy('item_id').get();

      var items = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'docId': doc.id,
          'item_id': d['item_id'] ?? '',
          'item_name': d['item_name'] ?? '',
          'description': d['description'] ?? '',
          'balance': d['balance'] ?? 0,
          'price': (d['price'] ?? 0).toDouble(),
        };
      }).toList();

      allStockItems.assignAll(items);
      filteredStockItems.assignAll(items); //start karaddi serama penwa
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

  //cart ekata badu ekathu kara ganna widiya
  void addItemToCart(Map<String, dynamic> stock) {
    int index = selectedItems.indexWhere(
      (item) => item['name'] == stock['item_name'],
    );
    if (index >= 0) {
      increaseQty(index);
    } else {
      selectedItems.add({
        'id': stock['docId'], // To track which stock item is added
        'name': stock['item_name'],
        'quantity': 1,
        'price': stock['price'],
      });
      calculateTotal();
    }
  }

  void increaseQty(int index) {
    selectedItems[index]['quantity'] += 1;
    calculateTotal();
  }

  // Add item to local list
  void addItem(String name, int qty, double price) {
    selectedItems.add({'name': name, 'quantity': qty, 'price': price});
    selectedItems.refresh(); // Notify listeners of the change
    calculateTotal();
  }

  void decreaseQty(int index) {
    if (selectedItems[index]['quantity'] > 1) {
      selectedItems[index]['quantity']--;
    } else {
      selectedItems.removeAt(index);
    }
    selectedItems.refresh(); // Notify listeners of the change
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

  // Step 3: Save Sales Record
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

      // 1. 🔥 Firestore WriteBatch එකක් ආරම්භ කිරීම
      WriteBatch batch = _db.batch();

      // 2. Sale Document එකට අලුත් ID එකක් කලින්ම සාදා ගැනීම
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
      );

      // 3. Sale එක සේව් කරන්න Batch එකට ඇතුලත් කිරීම
      batch.set(saleRef, newSale.toMap());

      // 4. 🔄 Selected Items ලැයිස්තුව හරහා Loop එකක් යවමින් හැම Item එකකම Stock අඩු කිරීම
      for (var item in selectedItems) {
        // සාමාන්‍යයෙන් item map එකේ item_id හෝ id එක තියෙන්න ඕනේ. (Firestore doc ID එක string එකක් නම් ඒක ගන්න)
        // ඔයාගේ stock collection එකේ document ID එක මෙතනට දාන්න (e.g., product['id'] හෝ item['item_id'].toString())
        String productId = item['id'] ?? item['item_id'].toString();
        String itemName = item['name'] ?? item['item_name'] ?? 'Unknown Item';

        // විකුණපු ප්‍රමාණය (Qty) ලබා ගැනීම (int එකක් බවට ස්ථිර කරගන්නවා)
        int quantitySold = int.tryParse(item['quantity'].toString()) ?? 1;

        // /stock collection එකේ අදාල product එකට reference එක
        DocumentReference productRef = _db.collection('stock').doc(productId);

        // 🛑 වැදගත්: දැනට තියෙන balance එක database එකෙන් කියවන්නේ නැතුව,
        // Firestore FieldValue.increment() එකෙන් කෙලින්ම අඩු කරන්න පුළුවන් (Cost එක ඉතිරි වෙනවා)
        batch.update(productRef, {
          'balance': FieldValue.increment(-quantitySold), // Stock එක අඩු කරයි
          'updated_at': FieldValue.serverTimestamp(),
        });

        // 5. 📝 ඒ Item එකට අයිති /transactions සබ්-කොලෙක්ෂන් එකට Entry එකක් දැමීම
        DocumentReference transRef = productRef
            .collection('transactions')
            .doc();
        batch.set(transRef, {
          'quantity':
              -quantitySold, // ඔයා කලින් ඉල්ලපු විදිහට සෘණ අගයක් ලෙස (-5)
          'type': 'out',
          'note':
              'Sales Transaction (Order: ${saleRef.id})', // මේ සේල් එකේ ID එකත් නෝට් එකට දානවා, පස්සේ හොයන්න ලේසි වෙන්න
          'timestamp': FieldValue.serverTimestamp(),
          'item_name': itemName,
          // සටහන: FieldValue.increment පාවිච්චි කරන නිසා 'balance_after' එක කෙලින්ම batch එක ඇතුලෙදි ගන්න බැහැ.
          // ඒක ප්‍රශ්නයක් වෙන්නේ නැහැ, මොකද උඩ ප්‍රධාන balance එක හරියටම update වෙන නිසා.
        });
      }

      // 6. 🔥 එකවරම සියලුම Updates (Sale එක + හැම Item එකකම Stock + Transactions) Commit කිරීම
      await batch.commit();

      Get.snackbar("Success", "Sale recorded and stock updated successfully");

      // Clear cart and go back to main menu
      selectedItems.clear();
      amountController.clear();
      Get.offAll(() => const FrontPage());
    } catch (e) {
      Get.snackbar("Error", "Sale failed: $e");
      SnackBar(content: Text("Error saving sale: $e"));
    } finally {
      isLoading.value = false;
    }
  }
}
