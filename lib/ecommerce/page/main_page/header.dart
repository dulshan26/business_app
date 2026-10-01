import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 💡 පරණ get_core සහ navigation imports වෙනුවට මේ එක import එක ප්‍රමාණවත්
import 'package:own/ecommerce/cart/cart_item_page.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/home.dart';
import 'package:own/login/main_page.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 🛒 CartController එක find කරගන්නවා (කලින් පිටුවේදී put කරලා තියෙන නිසා මෙතන find කරන්න පුළුවන්)
    final CartController cartController = Get.put(CartController());

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🏷️ Logo and Brand Name
          Row(
            children: [
              Image.asset(
                'asset/logo.jpg',
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text(
                'techtonic.lk',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // 🧭 Navigation Items & Cart Icon
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Get.to(() => const HomePage());
                },
                child: const Text('Home'),
              ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () {
                  Get.to(() => const MainPage());
                },
                child: const Text('admin'),
              ),
              const SizedBox(width: 20),

              // ==========================================
              // 🛒 REAVTIVE SHOPPING CART ICON WITH BADGE
              // ==========================================
              Obx(() {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined, size: 26),
                      onPressed: () {
                        // Cart පිටුවට (CheckoutPage) navigate වෙනවා
                        Get.to(() => CartView());
                      },
                    ),
                    // Cart එක ඇතුළේ items තියෙනවා නම් විතරක් රතු පාට Badge එක පෙන්වනවා
                    if (cartController.totalItemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cartController.totalItemCount}',
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
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
