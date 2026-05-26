import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/orders/order_card.dart';
import 'package:own/getxpac/orders/sales_edit_page.dart';
import 'package:own/getxpac/sales/sales_model.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  // Status config: label, icon, color
  final List<_TabConfig> _tabs = const [
    _TabConfig('Pending', Icons.hourglass_top_rounded, Color(0xFFFF9800)),
    _TabConfig('Sent', Icons.local_shipping_rounded, Color(0xFF2196F3)),
    _TabConfig('Cash Collect', Icons.payments_rounded, Color(0xFF4CAF50)),
    _TabConfig('Return', Icons.assignment_return_rounded, Color(0xFFF44336)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.transparent,
          dividerColor: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          tabs: _tabs.map((tab) => _buildTab(tab)).toList(),
        ),
      ),
      body: StreamBuilder<List<SalesModel>>(
        stream: _firestoreService.getAllSalesOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final filtered = allOrders
                  .where((o) => o.status == tab.label)
                  .toList();
              return _buildOrderList(filtered, tab);
            }).toList(),
          );
        },
      ),
    );
  }

  // ── Tab chip UI ────────────────────────────────────────────────────────────
  Widget _buildTab(_TabConfig tab) {
    return StreamBuilder<List<SalesModel>>(
      stream: _firestoreService.getAllSalesOrders(),
      builder: (context, snapshot) {
        final count = snapshot.hasData
            ? snapshot.data!.where((o) => o.status == tab.label).length
            : 0;

        return AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final isSelected = _tabs[_tabController.index].label == tab.label;
            return Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tab.color.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? tab.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isSelected ? tab.color : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? tab.color : Colors.grey,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? tab.color : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Per-tab list (Responsive Grid & List) ──────────────────────────────────
  Widget _buildOrderList(List<SalesModel> orders, _TabConfig tab) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 56, color: tab.color.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              "No ${tab.label} orders",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final bool showSummary =
        tab.label == 'Cash Collect' || tab.label == 'Return';

    // 🛠️ ඩෙස්ක්ටොප් සහ මොබයිල් තිර හඳුනා ගැනීමට LayoutBuilder යොදා ඇත
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 600;

        return Column(
          children: [
            if (showSummary) _buildSummaryBanner(orders, tab),
            Expanded(
              child: isDesktop
                  ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 500,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent:
                            340, // 👈 බොත්තම් ලස්සනට පෙනීමට උස 340px දක්වා වැඩි කර ඇත
                      ),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildStatusAwareCard(
                          orders[index],
                          tab,
                          context,
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildStatusAwareCard(
                          orders[index],
                          tab,
                          context,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── Summary banner for Cash Collect / Return ────────────────────────────────
  Widget _buildSummaryBanner(List<SalesModel> orders, _TabConfig tab) {
    final total = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final isCash = tab.label == 'Cash Collect';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tab.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tab.color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tab.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCash ? "Total Cash to Collect" : "Total Return Value",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "Rs. ${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            "${orders.length} orders",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Card with left accent color per status ──────────────────────────────────
  // 🛠️ ClipRRect ඉවත් කර බටන්ස් පෙනෙන පරිදි සහ context එක නිවැරදිව ලැබෙන සේ සකසා ඇත
  Widget _buildStatusAwareCard(
    SalesModel sales,
    _TabConfig tab,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        // වම් පසින් ලස්සන පාට තීරුවක් (Status Color Bar)
        border: Border(left: BorderSide(color: tab.color, width: 5)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SalesOrderCard(
        order: sales,
        onTap: () => Get.to(() => SalesEditPage(sales: sales)),
        onDelete: () => _firestoreService.deleteOrderShow(
          sales.id!,
          context,
        ), // 👈 Get.context වෙනුවට සාමාන්‍ය context එක දී ඇත
      ),
    );
  }
}

// ── Simple config data class ────────────────────────────────────────────────
class _TabConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _TabConfig(this.label, this.icon, this.color);
}
