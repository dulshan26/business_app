import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/customer/customer_model.dart';
import 'package:own/getxpac/customer/customer_page.dart';
import 'package:own/getxpac/orders/order_page.dart';
import 'package:own/getxpac/sales/sales_model.dart';
import 'package:own/getxpac/sales_item/item_controller.dart';
import 'package:own/getxpac/sales_item/item_page.dart';
import 'package:own/getxpac/summery/banner_manager.dart';
import 'package:own/getxpac/summery/summery.dart';
import 'package:own/utils/sales_summery/sales_summery_controll.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  static const Color _navy = Color(0xFF102444);
  static const Color _navyDark = Color(0xFF0A1930);
  static const Color _teal = Color(0xFF26B8A5);
  static const Color _pageBackground = Color(0xFFF3F6FB);

  @override
  Widget build(BuildContext context) {
    final summaryController = Get.isRegistered<SalesSummeryControll>()
        ? Get.find<SalesSummeryControll>()
        : Get.put(SalesSummeryControll());
    final stockController = Get.isRegistered<StockListController>()
        ? Get.find<StockListController>()
        : Get.put(StockListController());

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.grid_view_rounded, color: _teal),
            SizedBox(width: 10),
            Text(
              'Techtonic',
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Get.to(() => const OrderPage()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1050;
            final content = _buildOverview(
              summaryController,
              stockController,
              isWide: isWide,
            );
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: content),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 360,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 22, right: 22),
                      child: _buildRecentActivity(),
                    ),
                  ),
                ],
              );
            }
            return content;
          },
        ),
      ),
    );
  }

  Widget _buildOverview(
    SalesSummeryControll summaryController,
    StockListController stockController, {
    required bool isWide,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 22, isWide ? 28 : 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 22),
              _buildSectionHeading(
                'Business overview',
                subtitle: 'A quick look at your store today',
              ),
              const SizedBox(height: 12),
              _buildStats(summaryController, stockController),
              const SizedBox(height: 28),
              _buildSectionHeading(
                'Quick actions',
                subtitle: 'Jump straight into your daily tasks',
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
              if (!isWide) ...[
                const SizedBox(height: 28),
                _buildRecentActivity(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.memory_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STORE MANAGEMENT',
                style: TextStyle(
                  color: _teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage sales, inventory, and customers from one place.',
                style: TextStyle(color: Color(0xFFC7D3E5), height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: showPhoneDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: _navyDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 19),
                label: const Text(
                  'Create a sale',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF73819A),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(
    SalesSummeryControll summaryController,
    StockListController stockController,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cards = [
          Obx(() {
            final summary = summaryController.summery.value;
            return _StatCard(
              title: 'Total revenue',
              value: summaryController.isLoading.value
                  ? 'Loading'
                  : 'LKR ${summary.totalRevenew.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF198A72),
              onTap: () => Get.to(() => const SalesDashboardView()),
            );
          }),
          Obx(
            () => _StatCard(
              title: 'Total orders',
              value: summaryController.isLoading.value
                  ? 'Loading'
                  : summaryController.summery.value.totalOrders.toString(),
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF4269B2),
              onTap: () => Get.to(() => const OrderPage()),
            ),
          ),
          Obx(
            () => _StatCard(
              title: 'Inventory items',
              value: stockController.isLoading.value
                  ? 'Loading'
                  : stockController.allProducts.length.toString(),
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFFB36B20),
              onTap: () => Get.to(() => const StockListPage()),
            ),
          ),
        ];

        if (compact) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }
        return Row(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(child: cards[index]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(
        title: 'Sales orders',
        subtitle: 'Review and update orders',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF4269B2),
        onTap: () {
          FirestoreService().syncAllCourierStatuses();
          Get.to(() => const OrderPage());
        },
      ),
      _ActionItem(
        title: 'Inventory',
        subtitle: 'Products, variants, and stock',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF198A72),
        onTap: () => Get.to(() => const StockListPage()),
      ),
      _ActionItem(
        title: 'Customers',
        subtitle: 'Customer records and details',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF9A5A9F),
        onTap: () => Get.to(() => const CustomerListPage()),
      ),
      _ActionItem(
        title: 'Store banner',
        subtitle: 'Manage the storefront hero',
        icon: Icons.wallpaper_outlined,
        color: const Color(0xFFB36B20),
        onTap: () => Get.to(() => const AdminBannerManager()),
      ),
      _ActionItem(
        title: 'Sales summary',
        subtitle: 'Revenue and order totals',
        icon: Icons.insights_outlined,
        color: const Color(0xFF376A96),
        onTap: () => Get.to(() => const SalesDashboardView()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) => _ActionCard(item: actions[index]),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent orders',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const OrderPage()),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          StreamBuilder<List<SalesModel>>(
            stream: FirestoreService().getAllSalesOrders(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _ActivityMessage(
                  icon: Icons.cloud_off_outlined,
                  message: 'Could not load recent orders.',
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator(color: _teal)),
                );
              }
              final orders = snapshot.data!
                  .where(
                    (order) => const {
                      'pending',
                      'sent',
                    }.contains(order.status.trim().toLowerCase()),
                  )
                  .take(5)
                  .toList();
              if (orders.isEmpty) {
                return const _ActivityMessage(
                  icon: Icons.receipt_long_outlined,
                  message: 'No pending or sent orders.',
                );
              }
              return Column(
                children: orders
                    .map(
                      (order) => ListTile(
                        onTap: () => Get.to(() => const OrderPage()),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEAF2FF),
                          foregroundColor: _navy,
                          child: const Icon(Icons.receipt_outlined, size: 19),
                        ),
                        title: Text(
                          (order.customerName?.trim().isNotEmpty ?? false)
                              ? order.customerName!
                              : order.customerPhone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${order.status} · ${order.items.length} item(s)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Courier: ${order.courierStatus?.trim().isNotEmpty == true ? order.courierStatus!.trim() : 'Not updated'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF52657F),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          'LKR ${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF198A72),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 105),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF73819A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102444),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EBF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102444),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF73819A),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9BA8BA),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ActivityMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8A98AD)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF73819A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

void showPhoneDialog() {
  final phoneController = TextEditingController();
  final customerController = Get.isRegistered<CustomerController>()
      ? Get.find<CustomerController>()
      : Get.put(CustomerController());

  Get.dialog<void>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Start a new sale',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: phoneController,
        autofocus: true,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
          LengthLimitingTextInputFormatter(13),
        ],
        onSubmitted: (_) => _continueSale(phoneController, customerController),
        decoration: InputDecoration(
          labelText: 'Customer mobile number',
          hintText: '0771234567 or +94771234567',
          prefixIcon: const Icon(Icons.phone_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => _continueSale(phoneController, customerController),
          child: const Text('Continue'),
        ),
      ],
    ),
  ).whenComplete(phoneController.dispose);
}

Future<void> _continueSale(
  TextEditingController phoneController,
  CustomerController customerController,
) async {
  final enteredPhone = phoneController.text.trim();
  final phone = enteredPhone.startsWith('+94')
      ? '0${enteredPhone.substring(3)}'
      : enteredPhone.startsWith('94')
      ? '0${enteredPhone.substring(2)}'
      : enteredPhone;
  if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
    Get.snackbar(
      'Invalid phone number',
      'Enter a Sri Lankan mobile number, such as 0771234567.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  Get.back();
  await customerController.checkAndNavigate(phone);
}
