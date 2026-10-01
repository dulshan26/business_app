import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/customer/customer_form.dart';
import 'package:own/getxpac/sales/sales_page.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? phone2;
  final String? address;
  final bool? hasReturn;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.phone2,
    this.address,
    this.hasReturn,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'phone2': phone2,
      'address': address,
      'hasReturn': hasReturn,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      phone2: map['phone2'] ?? '',
      address: map['address'] ?? '',
      hasReturn: map['hasReturn'] ?? false,
    );
  }

  factory CustomerModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return CustomerModel(
      id: snap.id,
      name: data['name'] ?? 'No Name',
      phone: data['phone'] ?? 'No Phone',
      phone2: data['phone2'] ?? 'No Phone 2',
      address: data['address'] ?? 'No Address',
      hasReturn: data['hasReturn'] ?? false,
    );
  }
}

class CustomerController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Text Controllers for the form
  final nameController = TextEditingController();
  final phone2Controller = TextEditingController();
  final addressController = TextEditingController();

  var isLoading = false.obs;
  var isExistingCustomer = false.obs;
  var hasReturn = false.obs;
  String currentCustomerId = '';
  var customerList = <CustomerModel>[].obs;
  var searchQuery = "".obs;

  List<CustomerModel> get filteredCustomerList {
    if (searchQuery.value.isEmpty) {
      return customerList;
    }
    return customerList.where((customer) {
      final nameLower = customer.name.toLowerCase();
      final phone = customer.phone?.toLowerCase() ?? "";
      final phone2 = customer.phone2?.toLowerCase() ?? "";
      final searchLower = searchQuery.value.toLowerCase();

      return nameLower.contains(searchLower) ||
          phone.contains(searchLower) ||
          phone2.contains(searchLower);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchCustomersRealTime();
  }

  // Step 1: Check if customer exists
  Future<void> checkAndNavigate(String phone) async {
    isLoading.value = true;
    try {
      var query = await _db
          .collection('customers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        var customer = CustomerModel.fromSnapshot(doc);

        currentCustomerId = customer.id;
        nameController.text = customer.name;
        phone2Controller.text = customer.phone2 ?? '';
        addressController.text = customer.address ?? '';
        isExistingCustomer.value = true;
        hasReturn.value = customer.hasReturn ?? false;
      } else {
        currentCustomerId = '';
        nameController.clear();
        phone2Controller.clear();
        addressController.clear();
        isExistingCustomer.value = false;
        hasReturn.value = false;
      }

      Get.to(() => CustomerFormPage(phoneNumber: phone));
    } catch (e) {
      Get.snackbar("Error", "Search failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Save or Update Customer Details (FIXED: Added navigateToSales parameter)
  Future<void> saveCustomerDetails(
    String phone, {
    required bool navigateToSales,
  }) async {
    if (nameController.text.isEmpty) {
      Get.snackbar("Error", "Name is required");
      return;
    }

    try {
      isLoading.value = true;

      Map<String, dynamic> customerData = {
        'name': nameController.text.trim(),
        'phone': phone,
        'phone2': phone2Controller.text.trim(),
        'address': addressController.text.trim(),
        'hasReturn': hasReturn.value,
      };

      if (isExistingCustomer.value) {
        // Update existing
        await _db
            .collection('customers')
            .doc(currentCustomerId)
            .update(customerData);
      } else {
        customerData['hasReturn'] = false; // Default value for new customers

        // Create new and save its generated ID immediately
        DocumentReference docRef = await _db
            .collection('customers')
            .add(customerData);
        currentCustomerId = docRef.id;
        isExistingCustomer.value = true;
      }

      // Check where to route next based on the UI request
      if (navigateToSales) {
        Get.off(
          () => SalesEntryPage(
            customerPhone: phone,
            customerName: nameController.text.trim(),
            customerAddress: addressController.text.trim(),
            customerPhone2: phone2Controller.text.trim(),
          ),
        );
      } else {
        Get.back(); // Returns to previous screen safely
      }
    } catch (e) {
      Get.snackbar("Error", "Save failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markCustomerAsReturned(String phone) async {
    try {
      var query = await _db
          .collection('customers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var docRef = query.docs.first.reference;
        await docRef.update({'hasReturn': true});
        hasReturn.value = true;
        Get.snackbar("Success", "Customer marked as returned");
      } else {
        Get.snackbar("Error", "Customer not found");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to mark customer as returned: $e");
    }
  }

  void fetchCustomersRealTime() {
    _db.collection('customers').snapshots().listen((snapshot) {
      customerList.value = snapshot.docs
          .map((doc) => CustomerModel.fromSnapshot(doc))
          .toList();
    });
  }

  Future<void> fetchCustomerOnce() async {
    try {
      isLoading.value = true;
      var querySnapshot = await _db.collection('customers').get();
      customerList.value = querySnapshot.docs
          .map((doc) => CustomerModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      Get.snackbar("error", "Failed to fetch customer : $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    if (customerId.isEmpty) {
      Get.snackbar("error", "No cusotmer id");
      return;
    }
    try {
      isLoading.value = true;
      //delete form firebase
      await _db.collection('customers').doc(customerId).delete();

      Get.rawSnackbar(title: 'Deleted', message: "Customer removed successlly");
    } catch (e) {
      Get.snackbar('Error', 'Failed to deleted $e');
    } finally {
      isLoading.value = false;
    }
  }

  int get totalCustomerCount => customerList.length;

  int get filterCustomerCount => filteredCustomerList.length;

  List<CustomerModel> get normalCustomerList {
    return filteredCustomerList.where((c) => c.hasReturn == false).toList();
  }

  List<CustomerModel> get returnedCustomerList {
    return filteredCustomerList.where((c) => c.hasReturn == true).toList();
  }
}
