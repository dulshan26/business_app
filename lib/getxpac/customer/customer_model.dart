import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:own/getxpac/customer/customer_form.dart';
import 'package:own/getxpac/sales/sales_page.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? phone2;
  final String? address;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.phone2,
    this.address,
  });
  //covert model to Map(for save firebase)
  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'phone2': phone2, 'address': address};
  }

  //get data from firebase and convert to model
  factory CustomerModel.formMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      phone2: map['phone2'] ?? '',
      address: map['address'] ?? '',
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
  String currentCustomerId = '';

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
        // Customer Found: Pre-fill data
        var doc = query.docs.first;
        var customer = CustomerModel.fromSnapshot(doc);

        currentCustomerId = customer.id;
        nameController.text = customer.name;
        phone2Controller.text = customer.phone2 ?? '';
        addressController.text = customer.address ?? '';
        isExistingCustomer.value = true;
      } else {
        // New Customer: Clear fields
        currentCustomerId = '';
        nameController.clear();
        phone2Controller.clear();
        addressController.clear();
        isExistingCustomer.value = false;
      }

      // Navigate to the form page
      Get.to(() => CustomerFormPage(phoneNumber: phone));
    } catch (e) {
      Get.snackbar("Error", "Search failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Save or Update Customer Details
  Future<void> saveCustomerDetails(String phone) async {
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
      };

      if (isExistingCustomer.value) {
        // Update existing
        await _db
            .collection('customers')
            .doc(currentCustomerId)
            .update(customerData);
      } else {
        // Create new
        await _db.collection('customers').add(customerData);
      }
      Get.to(
        () => SalesEntryPage(
          customerPhone: phone,
          customerName: nameController.text.trim(),
          customerAddress: addressController.text.trim(),
          customerPhone2: phone2Controller.text.trim(),
        ),
      );
      Get.snackbar("Success", "Customer details saved.");
    } catch (e) {
      Get.snackbar("Error", "Save failed: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
