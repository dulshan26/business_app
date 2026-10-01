import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> openWhatsAppChat({
    required String message, // මුලින්ම auto type වෙන්න ඕන මැසේජ් එක
  }) async {
    // 🌟 WhatsApp API URL එක සකස් කරගැනීම (Uri.encodeFull මඟින් spaces ලස්සනට %20 වලට හරවනවා)
    final String url =
        "https://wa.me/+94779833106?text=${Uri.encodeFull(message)}";
    final Uri whatsappUri = Uri.parse(url);

    try {
      // 🌟 External Application එකක් විදිහට (WhatsApp App එකෙන්ම) open කරන්න උත්සාහ කරනවා
      if (await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Sent", "whatsapp message sent");
      } else {
        throw "Could not launch WhatsApp";
      }
    } catch (e) {
      debugPrint("WhatsApp Error: $e");
      // App එක නැත්නම් Browser එකෙන් හරි open වෙන්න සලස්වන්න පුළුවන්
    }
  }
}
