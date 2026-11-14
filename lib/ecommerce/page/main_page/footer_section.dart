import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/page/home.dart';
import 'package:own/ecommerce/page/sales_page.dart';
import 'package:own/login/main_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  // Helper method to safely launch external URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      color: const Color(0xFF061126),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          // Upper Grid Section
          Wrap(
            spacing: 40,
            runSpacing: 30,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Column 1: Store Brand & About
              SizedBox(
                width: isMobile ? double.infinity : 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Techtonic.lk - Smart Solutions for Modern Living",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Your one-stop shop for quality products. Fast delivery and 24/7 customer support.",
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                  ],
                ),
              ),

              // Column 2: Quick Links
              SizedBox(
                width: isMobile ? double.infinity : 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Links",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _footerLink("Home", () => Get.off(() => const HomePage())),
                    _footerLink(
                      "Shop Products",
                      () => Get.off(() => const SalesPage()),
                    ),
                    _footerLink("Privacy Policy", () {
                      () => Get.to(() => const MainPage());
                    }),
                    _footerLink("Terms & Conditions", () {}),
                    _footerLink("admin", () => Get.to(() => const MainPage())),
                  ],
                ),
              ),

              // Column 3: Contact Information
              SizedBox(
                width: isMobile ? double.infinity : 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact Us",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _contactRow(
                      Icons.location_on_outlined,
                      "No 95/B, Dharmashoka mawatha, Aruppola, Kandy, Sri Lanka",
                    ),
                    _contactRow(Icons.phone_outlined, "+94 77 98 33106"),
                    _contactRow(
                      Icons.email_outlined,
                      "infor.smartfinance@gmail.com",
                    ),
                  ],
                ),
              ),

              // Column 4: Social Media Channels
              SizedBox(
                width: isMobile ? double.infinity : 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Follow Us",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _socialButton(
                          icon: Icons.facebook,
                          onPressed: () => _launchURL(
                            "https://www.facebook.com/profile.php?id=61568380206487",
                          ),
                        ),
                        const SizedBox(width: 8),
                        _socialButton(
                          icon: Icons.camera_alt, // Represents Instagram
                          onPressed: () => _launchURL(
                            "https://www.instagram.com/tech.tonic24/",
                          ),
                        ),
                        const SizedBox(width: 8),
                        _socialButton(
                          icon: Icons.chat_bubble, // Represents WhatsApp
                          onPressed: () =>
                              _launchURL("https://wa.me/94779833106"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 20),

          // Bottom Section: Copyright
          const Text(
            "© 2026 My Store. All rights reserved.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Reusable widget for Quick Links
  Widget _footerLink(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  // Reusable widget for Contact Information Rows
  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF35D0BA), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget for Social Media Buttons
  Widget _socialButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17345C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
