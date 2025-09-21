// lib/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:own/constant/app_constant.dart';
import 'package:own/models/order_model.dart';
import 'package:own/pages/cash_page.dart';
import 'package:own/pages/item.dart';
import 'package:own/pages/sale.dart';
import 'package:own/pages/sales_data.dart';
import 'package:own/widget/recent_order.dart';
import 'package:own/widget/summeryCard.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  // Mock data for recent orders
  final List<Order> _recentOrders = [
    Order(
      id: '8572',
      customerName: 'John Doe',
      amount: 150.00,
      status: OrderStatus.Sent,
    ),
    Order(
      id: '8571',
      customerName: 'Jane Smith',
      amount: 75.50,
      status: OrderStatus.Pending,
    ),
    Order(
      id: '8570',
      customerName: 'Sam Wilson',
      amount: 220.25,
      status: OrderStatus.CashCollect,
    ),
    Order(
      id: '8569',
      customerName: 'Emily Brown',
      amount: 45.00,
      status: OrderStatus.Sent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800; // breakpoint for tablet/desktop

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 1,
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.new_label_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesOrderPage()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards Grid
                GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.5 : 1.2,
                  children: [
                    SummaryCard(
                      title: 'New Orders',
                      value: '12',
                      icon: Icons.hourglass_top_rounded,
                      iconColor: AppColors.pendingStatus,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesOrderPage()),
                      ),
                    ),
                    SummaryCard(
                      title: 'Sent',
                      value: '35',
                      icon: Icons.local_shipping_outlined,
                      iconColor: AppColors.sentStatus,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesListPage()),
                      ),
                    ),
                    SummaryCard(
                      title: 'Cash Collect',
                      value: '\$1,250',
                      icon: Icons.attach_money_rounded,
                      iconColor: AppColors.cashCollectStatus,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CashPage()),
                        );
                      },
                    ),
                    SummaryCard(
                      title: 'Stock',
                      value: '450',
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderItemsPage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Total Sales Card (Responsive full width)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Total Sales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '\$5,430.50',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Orders Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Recent Orders', style: AppTextStyles.sectionTitle),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsive List / Grid for Recent Orders
                isWide
                    ? GridView.builder(
                        itemCount: _recentOrders.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 3.5,
                            ),
                        itemBuilder: (context, index) {
                          return RecentOrderItem(order: _recentOrders[index]);
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentOrders.length,
                        itemBuilder: (context, index) {
                          return RecentOrderItem(order: _recentOrders[index]);
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
