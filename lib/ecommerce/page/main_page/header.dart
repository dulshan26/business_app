import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 💡 පරණ get_core සහ navigation imports වෙනුවට මේ එක import එක ප්‍රමාණවත්
import 'package:own/ecommerce/cart/cart_item_page.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/home.dart';
import 'package:own/ecommerce/page/sales_page.dart';
import 'package:own/login/main_page.dart';

class HeaderSection extends StatelessWidget {
  final String activePage;

  const HeaderSection({super.key, this.activePage = 'home'});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF07152F),
        border: Border(bottom: BorderSide(color: Color(0xFF1E3558))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Row(
            children: [
              Image.asset(
                'asset/logo.jpg',
                height: compact ? 34 : 40,
                width: compact ? 34 : 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'techtonic.lk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 17 : 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              _navButton(
                label: 'Home',
                isActive: activePage == 'home',
                onPressed: () => Get.off(() => const HomePage()),
                compact: compact,
              ),
              _navButton(
                label: 'Shop',
                isActive: activePage == 'shop',
                onPressed: () => Get.off(() => const SalesPage()),
                compact: compact,
              ),
              Obx(
                () => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Shopping cart',
                      onPressed: () => Get.to(() => CartView()),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                      ),
                    ),
                    if (cartController.totalItemCount > 0)
                      Positioned(
                        right: 3,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF35D0BA),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cartController.totalItemCount}',
                            style: const TextStyle(
                              color: Color(0xFF07152F),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!compact)
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (value) {
                    if (value == 'admin') Get.to(() => const MainPage());
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _navButton({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required bool compact,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? const Color(0xFF35D0BA) : Colors.white70,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          fontSize: compact ? 13 : 14,
        ),
      ),
    );
  }
}
