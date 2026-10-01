import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/home.dart';
import 'package:own/getxpac/customer/customer_model.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class WebCheckoutFormPage extends StatefulWidget {
  const WebCheckoutFormPage({super.key});

  @override
  State<WebCheckoutFormPage> createState() => _WebCheckoutFormPageState();
}

class _WebCheckoutFormPageState extends State<WebCheckoutFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  final CustomerController customerController =
      Get.isRegistered<CustomerController>()
      ? Get.find<CustomerController>()
      : Get.put(CustomerController());

  final SalesController salesController = Get.isRegistered<SalesController>()
      ? Get.find<SalesController>()
      : Get.put(SalesController());

  @override
  void dispose() {
    _phoneController.dispose();
    _phone2Controller.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Delivery & Customer Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        bool isPageLoading =
            salesController.isLoading.value ||
            customerController.isLoading.value;

        // 🎯 Delivery Charge එක සහ Final Total එක ගණනය කිරීම
        const double deliveryCharge = 400.00;
        double subTotal = salesController.totalAmount.value;
        double finalTotal = subTotal + deliveryCharge;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      "Please fill out your shipping information to complete the order.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // 1. Primary Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: "Phone Number (07xxxxxxxx)",
                        prefixIcon: const Icon(Icons.phone),
                        counterText: "", // 💡 Counter text එක සඟවයි
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        } else if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Secondary Phone Number
                    TextFormField(
                      controller: _phone2Controller,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Alternative Phone Number (Optional)",
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Customer Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Full Name *",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),

                    // 4. Customer Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: "Delivery Address *",
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your delivery address'
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // 🛍️ Detailed Bill Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Subtotal:",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Rs. ${subTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Delivery Fee:",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Rs. 400.00",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Payable:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Rs. ${finalTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🚀 Submit / Place Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isPageLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  try {
                                    salesController.isLoading.value = true;

                                    String phone = _phoneController.text.trim();
                                    String name = _nameController.text.trim();
                                    String address = _addressController.text
                                        .trim();
                                    String phone2 = _phone2Controller.text
                                        .trim();

                                    // 🎯 IMPORTANT: Firebase එකට යන්න කලින් Controller එක ඇතුලෙත් Delivery Charge එක එකතු කරපු Total එකම Update කරනවා
                                    salesController.totalAmount.value =
                                        finalTotal;

                                    final FirebaseFirestore db =
                                        FirebaseFirestore.instance;

                                    // I. Customer Update Logic
                                    var existingCusQuery = await db
                                        .collection('customers')
                                        .where('phone', isEqualTo: phone)
                                        .limit(1)
                                        .get();

                                    Map<String, dynamic> customerMap = {
                                      'name': name,
                                      'phone': phone,
                                      'phone2': phone2,
                                      'address': address,
                                    };

                                    if (existingCusQuery.docs.isNotEmpty) {
                                      String docId =
                                          existingCusQuery.docs.first.id;
                                      await db
                                          .collection('customers')
                                          .doc(docId)
                                          .update(customerMap);
                                    } else {
                                      await db
                                          .collection('customers')
                                          .add(customerMap);
                                    }

                                    // II. Real Batch Order Processing
                                    bool orderSuccess = await salesController
                                        .placeWebOrder(
                                          phone: phone,
                                          name: name,
                                          address: address,
                                          phone2: phone2,
                                        );

                                    if (orderSuccess) {
                                      final CartController cartController =
                                          Get.find<CartController>();
                                      cartController.cartItems
                                          .clear(); // Cart එක clear කිරීම

                                      Get.defaultDialog(
                                        title: "🎉 Order Successful!",
                                        middleText:
                                            "Your order has been securely placed.",
                                        textConfirm: "Back to Home",
                                        buttonColor: Colors.black,
                                        confirmTextColor: Colors.white,
                                        barrierDismissible: false,
                                        onConfirm: () =>
                                            Get.offAll(() => const HomePage()),
                                      );
                                    } else {
                                      Get.snackbar(
                                        "Order Failed",
                                        "Could not place order. Please check item availability.",
                                        backgroundColor: Colors.amber,
                                      );
                                    }
                                  } catch (e) {
                                    Get.snackbar(
                                      "Error",
                                      "Checkout failed: $e",
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  } finally {
                                    salesController.isLoading.value = false;
                                  }
                                }
                              },
                        child: const Text(
                          "Confirm & Place Order",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isPageLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              ),
          ],
        );
      }),
    );
  }
}
