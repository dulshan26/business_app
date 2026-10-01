import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/cart/whatsapp_cart.dart';
import 'package:own/ecommerce/controller/cart_controller.dart';
import 'package:own/utils/whatsapp.dart'; // ඔයාගේ path එක

class CheckoutController extends GetxController {
  final nameController = TextEditingController();
  final addressController = TextEditingController();

  final CartController cartController = Get.find<CartController>();

  // Delivery Fee එක fixed variable එකක් විදිහට ගන්නවා
  final double deliveryFee = 400.0;

  // Total computation properties
  double get subTotal => cartController.totalAmount;
  double get grandTotal => subTotal + deliveryFee;

  void placeOrderViaWhatsApp() async {
    String name = nameController.text.trim();
    String address = addressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in your Name and Address",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (cartController.cartItems.isEmpty) {
      Get.snackbar("Error", "Your cart is empty");
      return;
    }

    List<Map<String, dynamic>> itemsList = cartController.cartItems.values
        .toList();

    // Message එක format කරනවා delivery එකත් එක්කම
    String formattedMessage = generateWhatsAppMessage(
      name: name,
      address: address,
      cartItems: itemsList,
      subTotal: subTotal,
      deliveryFee: deliveryFee,
    );

    // WhatsApp open කරනවා
    await WhatsAppService.openWhatsAppChat(message: formattedMessage);

    // 🧹 Cart එක clear කරනවා
    cartController.clearCart();
    nameController.clear();
    addressController.clear();

    // 🏠 කෙලින්ම Home Page එකට යවනවා (Back stack එක clear කරලා)
    // 💡 Note: ඔයා Named Routes පාවිච්චි කරනවා නම් Get.offAllNamed('/home'); දාන්න.
    // නැත්නම් ඔයාගේ HomeView widget එක කෙලින්ම මෙතනට pass කරන්න:
    // Get.offAll(() => HomeView());
    Get.offAllNamed('/');
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
