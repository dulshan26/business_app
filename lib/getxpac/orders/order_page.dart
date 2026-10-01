import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:own/firebase/firestore.dart';
import 'package:own/getxpac/orders/order_card.dart';
import 'package:own/getxpac/orders/sales_edit_page.dart';
import 'package:own/getxpac/sales/sales_model.dart';
import 'package:own/getxpac/service/invoice.dart';
import 'package:printing/printing.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  // 🔎 Search Variables
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  final List<_TabConfig> _tabs = const [
    _TabConfig('Pending', Icons.hourglass_top_rounded, Color(0xFFFF9800)),
    _TabConfig('Sent', Icons.local_shipping_rounded, Color(0xFF2196F3)),
    _TabConfig('Cash Collect', Icons.payments_rounded, Color(0xFF4CAF50)),
    _TabConfig('Return', Icons.assignment_return_rounded, Color(0xFFF44336)),
    _TabConfig('All', Icons.all_inbox_rounded, Color(0xFF607D8B)),
    _TabConfig('Web Sales', Icons.language_rounded, Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🗓️ Group Orders by Date Category Helper
  Map<String, List<SalesModel>> _groupOrdersByDate(List<SalesModel> orders) {
    final Map<String, List<SalesModel>> grouped = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var order in orders) {
      // Assumes order.createdAt or fallback to order.date (adjust parameter if needed)
      final DateTime orderDate = order.createdAt;

      String dateHeader;
      // ignore: dead_code
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);

      if (orderDay == today) {
        dateHeader = 'Today';
      } else if (orderDay == yesterday) {
        dateHeader = 'Yesterday';
      } else if (now.difference(orderDate).inDays < 7) {
        dateHeader = DateFormat('EEEE').format(orderDate); // e.g. "Monday"
      } else {
        dateHeader = DateFormat(
          'dd MMM yyyy',
        ).format(orderDate); // e.g. "12 Mar 2026"
      }

      if (!grouped.containsKey(dateHeader)) {
        grouped[dateHeader] = [];
      }
      grouped[dateHeader]!.add(order);
    }

    return grouped;
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildSearchBar(),
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

          return Obx(() {
            final query = _searchQuery.value;

            // 1. Filter by Search Query
            final searchedOrders = allOrders.where((order) {
              if (query.isEmpty) return true;

              final customerName = order.customerName?.toLowerCase() ?? '';
              final customerPhone = order.customerPhone;
              final orderId = order.id?.toLowerCase() ?? '';

              return customerName.contains(query) ||
                  customerPhone.contains(query) ||
                  orderId.contains(query);
            }).toList();

            // 2. Tab Filter and List
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

  // ── Per-tab list with Grouped Date Headers ──────────────────────────────────
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
        tab.label == 'Cash Collect' ||
        tab.label == 'Return' ||
        tab.label == 'Web Sales';

    // Group the orders by date category
    final groupedOrders = _groupOrdersByDate(orders);

    return Column(
      children: [
        if (showSummary) _buildSummaryBanner(orders, tab),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: groupedOrders.keys.length,
            itemBuilder: (context, groupIndex) {
              final dateHeader = groupedOrders.keys.elementAt(groupIndex);
              final groupItems = groupedOrders[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🗓️ Date Section Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Text(
                          dateHeader,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${groupItems.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Order Items under this date
                  ...groupItems.map((order) {
                    return _buildStatusAwareCard(
                      order,
                      tab.label == 'All'
                          ? _tabs.firstWhere(
                              (t) => t.label == order.status,
                              orElse: () => tab,
                            )
                          : tab,
                      context,
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Summary banner for Cash Collect / Return / Web Sales ────────────────────
  Widget _buildSummaryBanner(List<SalesModel> orders, _TabConfig tab) {
    final total = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    String title = "Total Value";
    if (tab.label == 'Cash Collect') title = "Total Cash to Collect";
    if (tab.label == 'Return') title = "Total Return Value";
    if (tab.label == 'Web Sales') title = "Total Web Sales Revenue";

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
                title,
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
        // 📄 Action to open the Invoice PDF Preview
        onPdfPressed: () => openInvoicePdfPreview(context, sales),
      ),
    );
  }

  void openInvoicePdfPreview(BuildContext context, SalesModel sales) async {
    // Load logo from assets if available
    Uint8List? logoBytes;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/logo.png');
      logoBytes = bytes.buffer.asUint8List();
    } catch (_) {
      logoBytes = null; // Falls back to text header
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Invoice #${sales.id ?? ""}')),
          body: PdfPreview(
            build: (format) => InvoicePdfService.generateInvoice(
              sales: sales,
              logoBytes: logoBytes,
            ),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
          ),
        ),
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
