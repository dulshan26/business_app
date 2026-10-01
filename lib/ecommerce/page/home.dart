import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:own/ecommerce/cart/cart_item_page.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/main_page/category_section.dart';
import 'package:own/ecommerce/page/main_page/feature_product.dart';
import 'package:own/ecommerce/page/main_page/footer_section.dart';
import 'package:own/ecommerce/page/main_page/header.dart';
import 'package:own/ecommerce/page/main_page/hero_banner.dart';
import 'package:own/ecommerce/page/main_page/leatet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject globally once
    final CartController cartController = Get.put(
      CartController(),
      permanent: true,
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeaderSection(),
            HeroBanner(),
            CategorySection(),
            FeaturedProducts(),
            LatestProducts(),
            FooterSection(),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        final itemCount = cartController.totalItemCount;

        return FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () => Get.to(() => CartView()),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 24,
              ),
              if (itemCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
