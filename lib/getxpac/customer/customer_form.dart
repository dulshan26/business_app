import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:own/getxpac/customer/customer_model.dart';

class CustomerFormPage extends StatelessWidget {
  final String phoneNumber;
  CustomerFormPage({super.key, required this.phoneNumber});

  final controller = Get.find<CustomerController>();

  @override
  Widget build(BuildContext context) {
    // 🔴 Obx එකකින් මුළු Screen එකම Wrap කර ඇත (Return status එක අනුව පාට වෙනස් වීමට)
    return Obx(() {
      final isReturn = controller.hasReturn.value;

      // Color Theme Settings
      final primaryColor = isReturn ? Colors.red.shade700 : Colors.blue;
      final backgroundColor = isReturn ? Colors.red.shade50 : Colors.white;
      final cardColor = isReturn ? Colors.red.shade100 : Colors.grey.shade100;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: isReturn ? Colors.red.shade700 : null,
          foregroundColor: isReturn ? Colors.white : null,
          title: Text(
            controller.isExistingCustomer.value
                ? (isReturn
                      ? "Edit Customer (RETURN CUSTOMER)"
                      : "Edit Customer")
                : "Register Customer",
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔴 Return Customer Banner Alert
                if (isReturn)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "WARNING: This is a Return Customer!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Primary Phone Container
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: const Text("Primary Phone"),
                    subtitle: Text(
                      phoneNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isReturn ? Colors.red.shade900 : Colors.black,
                      ),
                    ),
                    leading: Icon(Icons.phone, color: primaryColor),
                  ),
                ),
                const SizedBox(height: 15),

                // Name TextField
                TextField(
                  controller: controller.nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name*",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Secondary Phone TextField
                TextField(
                  controller: controller.phone2Controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: "Secondary Phone (Optional)",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Address TextField
                TextField(
                  controller: controller.addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Address",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    // Button 1: Save Only
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReturn
                                ? Colors.red.shade100
                                : Colors.grey[200],
                            foregroundColor: isReturn
                                ? Colors.red.shade900
                                : Colors.black,
                          ),
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.saveCustomerDetails(
                                  phoneNumber,
                                  navigateToSales: false,
                                ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Save Only"),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Button 2: Next: Add Items
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.saveCustomerDetails(
                                  phoneNumber,
                                  navigateToSales: true,
                                ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Next: Add Items"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
