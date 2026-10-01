import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/ecommerce/page/single_product.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';

class LatestProducts extends GetView<StockListController> {
  const LatestProducts({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<StockListController>(() => StockListController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      // 1. Only show active products
      final activeProducts = controller.products
          .where((product) => product['isActive'] == true)
          .toList();

      // 🌟 2. Selection status එක check කිරීම
      final currentSelection = controller.selectedCategory.value.toLowerCase();
      List<dynamic> filteredProducts = [];

      if (currentSelection.isEmpty) {
        // 🚀 කිසිම එකක් select කරලා නැත්නම් (Initial හෝ Deselect අවස්ථාවක) සියල්ල පෙන්වයි
        filteredProducts = List.from(activeProducts);
      } else {
        // 🎯 Category එකක් select කරලා තිබේ නම් filter කරයි
        filteredProducts = activeProducts.where((product) {
          final cat = (product['category'] ?? '').toString().toLowerCase();

          if (currentSelection == 'smart things') {
            return cat == 'smart things';
          } else if (currentSelection == 'accessories') {
            return cat == 'accessories';
          } else {
            return cat != 'smart things' && cat != 'accessories';
          }
        }).toList();
      }
      // 🔤 NEW: Product Name එක අනුව A to Z පිළිවෙලට Sort කිරීම
      filteredProducts.sort((a, b) {
        final nameA = (a['item_name'] ?? '').toString().toLowerCase();
        final nameB = (b['item_name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (filteredProducts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  "No items available in this category",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final bool isDesktop = width >= 1024;
          final bool isTablet = width >= 600 && width < 1024;

          final int crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);
          final double spacing = isDesktop ? 20 : (isTablet ? 16 : 14);
          final double aspectRatio = isDesktop
              ? 0.78
              : (isTablet ? 0.72 : 0.68);
          final double maxContentWidth = isDesktop ? 1400 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 0 : 16,
                  8,
                  isDesktop ? 0 : 16,
                  24,
                ),
                itemCount: filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing + 4,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (_, index) {
                  return _ProductCard(
                    product: filteredProducts[index],
                    isDesktop: isDesktop,
                  );
                },
              ),
            ),
          );
        },
      );
    });
  }
}

// 🌟 _ProductCard එක සාමාන්‍ය විදිහටම යටින් තියාගන්න මචං.
class _ProductCard extends StatefulWidget {
  final dynamic product;
  final bool isDesktop;
  const _ProductCard({required this.product, required this.isDesktop});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovering = false;

  // 🛒 Cart Controller
  final CartController cartController = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // 🖼️ FIX: GET MAIN IMAGE FIRST
    String? imageUrl = product['main_image']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        imageUrl = images[0]?.toString();
      }
    }

    final hasImage =
        imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http');

    final balance = product['balance'] ?? 0;
    final isOutOfStock = balance == 0;
    final isLowStock = balance is num && balance > 0 && balance <= 5;

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Hero(
            tag: 'product-${product['id'] ?? product['item_name']}',
            child: AnimatedScale(
              scale: widget.isDesktop && _hovering ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: widget.isDesktop && _hovering
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(color: const Color(0xFFF6F6F8));
                            },
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey.shade300,
                                size: 28,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey.shade300,
                              size: 32,
                            ),
                          ),
                    if (isOutOfStock)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      )
                    else if (isLowStock)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Only $balance left',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // 🛒 FLOATING ADD TO CART BUTTON
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: isOutOfStock
                            ? null
                            : () => cartController.addToCart(product),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOutOfStock ? Colors.grey : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          product['item_name'] ?? 'Unknown Item',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: widget.isDesktop ? 14.5 : 13.5,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Rs. ${(product['price'] ?? 0).toString()}",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: widget.isDesktop ? 15 : 14,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );

    final tappable = GestureDetector(
      onTap: () => Get.to(() => OneItemPage(product: product)),
      child: card,
    );

    if (!widget.isDesktop) return tappable;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: tappable,
    );
  }
}
