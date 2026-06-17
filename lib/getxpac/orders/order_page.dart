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

  // 🔎 Search සඳහා අවශ්‍ය Variables
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  final List<_TabConfig> _tabs = const [
    _TabConfig('All', Icons.all_inbox_rounded, Color(0xFF607D8B)),
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
    _searchController.dispose(); // Memory leak නොවීමට මෙතනින් dispose කරන්න
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
        actions: [
          // Search Query එකක් තිබ්බොත් Clear බටන් එක පෙන්වන්න
          Obx(
            () => _searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery.value = '';
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
        // TabBar එකට උඩින් Search Bar එක දාන්න PreferredSize Widget එකක් පාවිච්චි කළා
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildSearchBar(), // 🔎 Search Bar එක මෙතනට දැම්මා
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                tabs: _tabs.map((tab) => _buildTab(tab)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<SalesModel>>(
        stream: _firestoreService.getAllSalesOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data!;

          // 🌟 Obx එක මඟින් User ටයිප් කරන කොටම UI එක වෙනස් කරයි
          return Obx(() {
            final query = _searchQuery.value;

            // 1. මුලින්ම මුළු ලිස්ට් එකම Search query එකට අනුව filter කරනවා
            final searchedOrders = allOrders.where((order) {
              if (query.isEmpty) return true;

              // ඔයාගේ SalesModel එකේ තියෙන parameters අනුව මේවා වෙනස් කරගන්න මල්ලි:
              final customerName = order.customerName?.toLowerCase() ?? '';
              final customerPhone = order.customerPhone;
              final orderId = order.id?.toLowerCase() ?? '';

              return customerName.contains(query) ||
                  customerPhone.contains(query) ||
                  orderId.contains(query);
            }).toList();

            // 2. ඊටපස්සේ ඒ filter වුන ලිස්ට් එක Tab එක අනුව බෙදනවා
            return TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = tab.label == 'All'
                    ? searchedOrders
                    : searchedOrders
                          .where((o) => o.status == tab.label)
                          .toList();

                return _buildOrderList(filtered, tab);
              }).toList(),
            );
          });
        },
      ),
    );
  }

  // 🔎 Search Bar UI Component
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _searchQuery.value = value.trim().toLowerCase();
        },
        decoration: InputDecoration(
          hintText: "Search name, phone or ID...",
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Tab chip UI ────────────────────────────────────────────────────────────
  Widget _buildTab(_TabConfig tab) {
    return StreamBuilder<List<SalesModel>>(
      stream: _firestoreService.getAllSalesOrders(),
      builder: (context, snapshot) {
        // 🌟 Tab එකේ උඩ පේන Count එකත් Search එකට අනුව live අප්ඩේට් වෙන්න හැදුවා
        return Obx(() {
          final query = _searchQuery.value;
          if (!snapshot.hasData) return _buildTabChip(tab, 0);

          final filteredBySearch = snapshot.data!.where((order) {
            if (query.isEmpty) return true;
            final name = order.customerName?.toLowerCase() ?? '';
            final phone = order.customerPhone;
            final id = order.id?.toLowerCase() ?? '';
            return name.contains(query) ||
                phone.contains(query) ||
                id.contains(query);
          });

          final count = tab.label == 'All'
              ? filteredBySearch.length
              : filteredBySearch.where((o) => o.status == tab.label).length;

          return _buildTabChip(tab, count);
        });
      },
    );
  }

  Widget _buildTabChip(_TabConfig tab, int count) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final isSelected = _tabs[_tabController.index].label == tab.label;
        return Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              _searchQuery.value.isEmpty
                  ? "No ${tab.label} orders"
                  : "No matching orders found",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final bool showSummary =
        tab.label == 'Cash Collect' || tab.label == 'Return';

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
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 500,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 340,
                          ),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildStatusAwareCard(
                          orders[index],
                          tab.label == 'All'
                              ? _tabs.firstWhere(
                                  (t) => t.label == orders[index].status,
                                  orElse: () => tab,
                                )
                              : tab,
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
                          tab.label == 'All'
                              ? _tabs.firstWhere(
                                  (t) => t.label == orders[index].status,
                                  orElse: () => tab,
                                )
                              : tab,
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
  Widget _buildStatusAwareCard(
    SalesModel sales,
    _TabConfig tab,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
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
        onDelete: () => _firestoreService.deleteOrderShow(sales.id!, context),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _TabConfig(this.label, this.icon, this.color);
}
