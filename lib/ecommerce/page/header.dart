import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:own/ecommerce/admin/admin_dashboard.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'techtonic.lk',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  // Navigate to Home
                },
                child: const Text('Home'),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {
                  // Navigate to Products
                },
                child: const Text('Products'),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {
                  Get.to(const AdminDashboard());
                },
                child: const Text('admin'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
