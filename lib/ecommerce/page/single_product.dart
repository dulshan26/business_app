import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/cart/cart_item_page.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/utils/whatsapp.dart';

class OneItemPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const OneItemPage({super.key, required this.product});

  @override
  State<OneItemPage> createState() => _OneItemPageState();
}

class _OneItemPageState extends State<OneItemPage> {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color accentColor = Color(0xFFFF6B35);
  static const Color bgColor = Color(0xFFF7F8FA);

  final PageController _pageController = PageController();
  final CartController cartController = Get.find<CartController>();

  int _currentImageIndex = 0;
  int _quantity = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // 🖼️ COMBINE MAIN IMAGE + GALLERY IMAGES
    final List<String> imageUrls = [];
    String? mainImg = product['main_image']?.toString();
    if (mainImg != null && mainImg.isNotEmpty) {
      imageUrls.add(mainImg);
    }

    final dynamic rawImages = product['images'];
    if (rawImages is List) {
      for (var img in rawImages) {
        String imgUrl = img.toString();
        if (imgUrl.isNotEmpty && imgUrl != mainImg) {
          imageUrls.add(imgUrl);
        }
      }
    }

    final String itemName = product['item_name'] ?? 'Unknown Item';
    final double price = (product['price'] ?? 0).toDouble();
    final int balance = product['balance'] ?? 0;
    final String description =
        product['description'] ?? 'No description available for this product.';
    final String category = product['category'] ?? 'General';
    final bool isOutOfStock = balance <= 0;
    final String productId = (product['id'] ?? product['item_name']).toString();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _circleIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Get.back(),
        ),
        title: Text(
          itemName,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Obx(
            () => Stack(
              children: [
                _circleIconButton(
                  icon: Icons.shopping_cart_outlined,
                  onTap: () => Get.to(() => CartView()),
                ),
                if (cartController.cartItems.isNotEmpty)
                  Positioned(
                    right: 2,
                    top: 2,
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
                        '${cartController.cartItems.length}',
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
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;

          return Column(
            children: [
              _buildCustomerTopHeader(),
              Expanded(
                child: isDesktop
                    ? _buildDesktopLayout(
                        imageUrls,
                        category,
                        isOutOfStock,
                        balance,
                        itemName,
                        price,
                        description,
                        productId,
                        product,
                      )
                    : _buildMobileLayout(
                        imageUrls,
                        category,
                        isOutOfStock,
                        balance,
                        itemName,
                        price,
                        description,
                        productId,
                        product,
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButtons(itemName, product, isOutOfStock, price),
              const SizedBox(height: 6),
              _buildFooterBranding(),
            ],
          ),
        ),
      ),
    );
  }

  // 💻 DESKTOP LAYOUT (Side-by-Side with large image container)
  Widget _buildDesktopLayout(
    List<String> imageUrls,
    String category,
    bool isOutOfStock,
    int balance,
    String itemName,
    double price,
    String description,
    String productId,
    Map<String, dynamic> product,
  ) {
    return Center(
      child: Container(
        width: 1100,
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Large Image Carousel
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 550, // Larger image frame for desktop
                child: _buildImageCarousel(imageUrls),
              ),
            ),
            const SizedBox(width: 32),
            // Right Column: Details & Actions
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(category, isOutOfStock, balance),
                    const SizedBox(height: 16),
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1B1F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "LKR ${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    if (!isOutOfStock) ...[
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildQuantitySelector(
                            balance,
                            productId,
                            product,
                            price,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📱 MOBILE LAYOUT (Vertical Stack)
  Widget _buildMobileLayout(
    List<String> imageUrls,
    String category,
    bool isOutOfStock,
    int balance,
    String itemName,
    double price,
    String description,
    String productId,
    Map<String, dynamic> product,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: Get.height * .35,
            child: _buildImageCarousel(imageUrls),
          ),
          const SizedBox(height: 16),
          _buildProductHeader(category, isOutOfStock, balance),
          const SizedBox(height: 16),
          Text(
            itemName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1F),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "LKR ${price.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B1B1F),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),
          const Text(
            "Description",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          if (!isOutOfStock) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Quantity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                _buildQuantitySelector(balance, productId, product, price),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductHeader(String category, bool isOutOfStock, int balance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            category.toUpperCase(),
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isOutOfStock ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOutOfStock ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOutOfStock
                    ? Icons.cancel_outlined
                    : Icons.check_circle_outline,
                size: 14,
                color: isOutOfStock
                    ? Colors.red.shade700
                    : Colors.green.shade700,
              ),
              const SizedBox(width: 5),
              Text(
                isOutOfStock ? "Out of stock" : "$balance in stock",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isOutOfStock
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    String itemName,
    Map<String, dynamic> product,
    bool isOutOfStock,
    double price,
  ) {
    if (isOutOfStock) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          "Out of Stock",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await WhatsAppService.openWhatsAppChat(
              message:
                  "Hello Techtonic. I would like to inquire about this product: $itemName (Qty: $_quantity)",
            );
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF25D366), width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF25D366),
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final productWithQty = Map<String, dynamic>.from(product);
                productWithQty['quantity'] = _quantity;
                productWithQty['max_balance'] = product['balance'];
                productWithQty['price'] = price;

                cartController.addToCart(productWithQty);

                setState(() {
                  _quantity = 1;
                });

                Get.snackbar(
                  "Success",
                  "$itemName added to cart successfully!",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withValues(alpha: 0.8),
                  colorText: Colors.white,
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Cart",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final productWithQty = Map<String, dynamic>.from(product);
                productWithQty['quantity'] = _quantity;
                productWithQty['max_balance'] = product['balance'];
                productWithQty['price'] = price;

                cartController.addToCart(productWithQty);

                setState(() {
                  _quantity = 1;
                });

                Get.to(() => CartView());
              },
              child: const Text(
                "Buy Now",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 80),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              final url = imageUrls[index];
              return Container(
                color: Colors.grey.shade100,
                width: double.infinity,
                child: url.startsWith('http')
                    ? Image.network(url, fit: BoxFit.contain)
                    : const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 60,
                        ),
                      ),
              );
            },
          ),
        ),
        if (imageUrls.length > 1)
          Container(
            height: 75,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Center(
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentImageIndex;
                  final url = imageUrls[index];

                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 55,
                      height: 55,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade300,
                          width: isSelected ? 2.5 : 1,
                        ),
                        image: url.startsWith('http')
                            ? DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !url.startsWith('http')
                          ? const Icon(
                              Icons.broken_image,
                              size: 20,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantitySelector(
    int balance,
    String productId,
    Map<String, dynamic> product,
    double price,
  ) {
    return Obx(() {
      bool isInCart = cartController.cartItems.containsKey(productId);
      int displayQuantity = isInCart
          ? cartController.cartItems[productId]!['quantity']
          : _quantity;

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _qtyButton(Icons.remove, () {
              if (isInCart) {
                cartController.decrementQuantity(productId);
              } else {
                if (_quantity > 1) setState(() => _quantity--);
              }
            }),
            SizedBox(
              width: 36,
              child: Text(
                '$displayQuantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            _qtyButton(Icons.add, () {
              if (isInCart) {
                cartController.incrementQuantity(productId);
              } else {
                if (_quantity < balance) setState(() => _quantity++);
              }
            }),
          ],
        ),
      );
    });
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildCustomerTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: primaryColor.withValues(alpha: 0.08),
      child: Row(
        children: const [
          Icon(Icons.local_shipping_outlined, color: primaryColor, size: 20),
          SizedBox(width: 8),
          Text(
            "Islandwide delivery Available",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBranding() {
    return const Center(
      child: Text(
        "Powered by Techtonic",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
