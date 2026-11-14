import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/cart/cart_item_page.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/main_page/footer_section.dart';
import 'package:own/ecommerce/page/main_page/header.dart';
import 'package:own/ecommerce/page/main_page/hero_banner.dart';
import 'package:own/ecommerce/page/sales_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    return Scaffold(
      backgroundColor: const Color(0xFF07152F),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HeaderSection(activePage: 'home'),
            const HeroBanner(),
            _HomeStoreContent(
              onShopPressed: () => Get.to(() => const SalesPage()),
            ),
            const FooterSection(),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        final itemCount = cartController.totalItemCount;
        return FloatingActionButton(
          backgroundColor: const Color(0xFF35D0BA),
          foregroundColor: const Color(0xFF07152F),
          tooltip: 'Open shopping cart',
          onPressed: () => Get.to(() => CartView()),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 24),
              if (itemCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7043),
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

class _HomeStoreContent extends StatelessWidget {
  final VoidCallback onShopPressed;

  const _HomeStoreContent({required this.onShopPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 680;
                  final intro = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SMARTER LIVING STARTS HERE',
                        style: TextStyle(
                          color: Color(0xFF35D0BA),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Technology that\nfits your life.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 34 : 48,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Discover smart devices, accessories, and practical tech selected for your home and everyday routine.',
                        style: TextStyle(
                          color: Color(0xFFB7C7DE),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: onShopPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF35D0BA),
                          foregroundColor: const Color(0xFF07152F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text(
                          'Explore the shop',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                  if (isCompact) return intro;
                  return Row(
                    children: [
                      Expanded(child: intro),
                      const SizedBox(width: 40),
                      Expanded(
                        child: InkWell(
                          onTap: () => Get.to(
                            () => const SalesPage(),
                          ), // Placeholder for potential future interaction
                          child: const _DeviceShowcase(),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 34),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final features = const [
                    _StoreFeature(
                      icon: Icons.devices_other_outlined,
                      title: 'Smart tech, made simple',
                      text: 'Useful devices chosen for real everyday needs.',
                    ),
                    _StoreFeature(
                      icon: Icons.verified_outlined,
                      title: 'Quality you can trust',
                      text: 'Shop dependable products with clear details.',
                    ),
                    _StoreFeature(
                      icon: Icons.support_agent_outlined,
                      title: 'Here when you need us',
                      text: 'Get friendly help choosing the right device.',
                    ),
                  ];
                  if (compact) {
                    return Column(
                      children: features
                          .map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: feature,
                            ),
                          )
                          .toList(),
                    );
                  }
                  return Row(
                    children: features
                        .map(
                          (feature) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: feature,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceShowcase extends StatelessWidget {
  const _DeviceShowcase();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17345C), Color(0xFF102543)],
        ),
        border: Border.all(color: const Color(0xFF2A4973)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            right: 34,
            child: Icon(
              Icons.wifi,
              color: const Color(0xFF35D0BA).withValues(alpha: 0.55),
              size: 52,
            ),
          ),
          const Icon(
            Icons.devices_other_rounded,
            size: 128,
            color: Color(0xFF35D0BA),
          ),
          const Positioned(
            left: 24,
            bottom: 22,
            child: Text(
              'CONNECTED. CONVENIENT. YOURS.',
              style: TextStyle(
                color: Color(0xFFB7C7DE),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _StoreFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102543),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF203A60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF35D0BA), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFB7C7DE),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
