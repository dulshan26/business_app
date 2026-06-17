import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:own/ecommerce/home.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/customer/customer_form.dart';
import 'package:own/getxpac/customer/customer_model.dart';
import 'package:own/getxpac/orders/order_page.dart';
import 'package:own/getxpac/sales_item/item_page.dart';
import 'package:own/utils/layout.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsibleLayouts(
      mobileBody: _buildMobileLayout(),
      desktopBody: _buildDesktopLayout(),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(isDesktop: false),
            _buildStatSummary(),
            _buildSectionTitle('Quick Actions'),
            _buildQuickActionsGrid(crossAxisCount: 2, aspectRatio: 1.4),
            _buildSectionTitle('Recent Activity'),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  // --- DESKTOP LAYOUT ---
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side Main Content (Takes up the majority of space)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBanner(isDesktop: true),
                  _buildStatSummary(),
                  _buildSectionTitle('Quick Actions'),
                  // Wider cards on desktop look cleaner with a 1.8 aspect ratio
                  _buildQuickActionsGrid(crossAxisCount: 2, aspectRatio: 1.8),
                ],
              ),
            ),
          ),

          // Vertical Divider
          VerticalDivider(width: 1, color: Colors.grey.withValues(alpha: 0.2)),

          // Right Side Sidebar (Dedicated panel for activities)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Recent Activity'),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildRecentActivityList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SHARED REFACTORED COMPONENTS ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Techtonic.lk',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {},
        ),
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
      ],
    );
  }

  // Modified to handle sharp corner designs on Desktop vs Mobile
  Widget _buildHeaderBanner({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: isDesktop
            ? BorderRadius
                  .zero // Keeps desktop looking clean and flat
            : const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back,',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Store Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Today\'s Sales',
              'Rs. 12,450',
              Icons.trending_up_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Active Customers',
              '48 Users',
              Icons.people_outline_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modified to take grid parameters for layout sizing changes
  Widget _buildQuickActionsGrid({
    required int crossAxisCount,
    required double aspectRatio,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: aspectRatio,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMenuCard(
          title: 'New Sale',
          icon: Icons.add_shopping_cart_rounded,
          color: Colors.blueAccent,
          onTap: () => showPhoneDialog(),
        ),
        _buildMenuCard(
          title: 'Customers Directory',
          icon: Icons.contact_page_outlined,
          color: Colors.purple,
          onTap: () {
            FirestoreService().syncAllCourierStatuses();
            Get.to(() => const OrderPage());
          },
        ),
        _buildMenuCard(
          title: 'Transaction History',
          icon: Icons.history_rounded,
          color: Colors.teal,
          onTap: () {
            Get.to(() => StockListPage());
          },
        ),
        _buildMenuCard(
          title: 'Analytics Reports',
          icon: Icons.bar_chart_rounded,
          color: Colors.redAccent,
          onTap: () {
            Get.to(() => const HomePage()); // Placeholder for analytics page
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.blueAccent,
              ),
            ),
            title: Text(
              'Customer Record #${1024 + index}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Completed • 10 mins ago',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Text(
              'Rs. 4,500',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}

void showPhoneDialog() {
  final phoneController = TextEditingController();
  final CustomerController controller = Get.put(CustomerController());

  Get.dialog(
    AlertDialog(
      title: const Text("Enter Mobile Number"),
      content: TextField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: "0771234567"),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            String phone = phoneController.text.trim();

            if (phone.isEmpty) {
              Get.snackbar(
                "Error",
                "Enter phone number",
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            } else if (phone.length != 10) {
              Get.snackbar(
                "Error",
                "Phone number must be 10 digits",
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }

            controller.checkAndNavigate(phone);

            // 🛠️ FIX: Close the dialog first and let the routing finish cleanly
            Get.back();
            Get.to(() => CustomerFormPage(phoneNumber: phone));

            // 🛠️ FIX: Allow the new page view engine state to settle before firing the snackbar
            await Future.delayed(const Duration(milliseconds: 100));

            Get.snackbar(
              "Success",
              "Navigating to customer form for $phone",
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          child: const Text("Continue"),
        ),
      ],
    ),
  );
}
