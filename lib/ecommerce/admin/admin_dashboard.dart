import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/admin/admin_product_list.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.to(() => const ProductListPage());
          },
          child: const Text("Manage Products"),
        ),
      ),
    );
  }
}
