import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  // Product එකකට navigate වෙන function එක
  void _navigateToProduct(String productId) async {
    if (productId.isEmpty) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
        productData['id'] = doc.id;
        // Get.to(() => OneItemPage(product: productData));
      } else {
        Get.snackbar("Error", "Product not found!");
      }
    } catch (e) {
      Get.snackbar("Error", "Error fetching product: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .doc('hero_banner')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        var bannerData = snapshot.data!.data() as Map<String, dynamic>;

        // Data extraction
        String bannerImg = bannerData['banner_image'] ?? '';
        String bannerTitle = bannerData['banner_title'] ?? 'Latest Products';
        String bannerSubtitle =
            bannerData['banner_subtitle'] ?? 'Best Deals Available';
        String p1Image = bannerData['product1_image'] ?? '';
        String p1Id = bannerData['product1_id'] ?? '';
        String p2Image = bannerData['product2_image'] ?? '';
        String p2Id = bannerData['product2_id'] ?? '';

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 🌅 1. BIG HERO BANNER (70% Height or Static Dynamic Content)
              Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: bannerImg.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(bannerImg),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: AssetImage('asset/Home_banner.png'),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bannerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bannerSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🛍️ 2. UNDER 2 PRODUCT IMAGES (Side by Side)
              Row(
                children: [
                  Expanded(
                    child: _buildProductCard(
                      imageUrl: p1Image,
                      onTap: () => _navigateToProduct(p1Id),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProductCard(
                      imageUrl: p2Image,
                      onTap: () => _navigateToProduct(p2Id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard({
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl.isEmpty
            ? const Icon(Icons.image_not_supported, color: Colors.grey)
            : null,
      ),
    );
  }
}
