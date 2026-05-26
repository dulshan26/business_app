import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:own/getxpac/customer/customer_model.dart';

class CustomerFormPage extends StatelessWidget {
  final String phoneNumber;
  CustomerFormPage({super.key, required this.phoneNumber});

  final controller = Get.put(CustomerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isExistingCustomer.value
              ? "Edit Customer"
              : "Register Customer",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Display the primary phone (Read-only)
              ListTile(
                title: const Text("Primary Phone"),
                subtitle: Text(phoneNumber),
                leading: const Icon(Icons.phone),
              ),
              const Divider(),

              TextField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name*",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: controller.phone2Controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  // Allow only digits and limit to 10 characters
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: "Secondary Phone (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: controller.addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.saveCustomerDetails(phoneNumber),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Next: Add Items"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
