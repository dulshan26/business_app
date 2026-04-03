import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:own/api_handler/royal.dart';
import 'package:own/app/constant/app_constant.dart';
import 'package:own/login/login_page_state.dart';
import 'package:own/sales/pages/salepage/sale.dart';
import 'package:own/sales/pages/salepage/sales_data.dart';
import 'package:own/provider/dashboard_provider.dart';
import 'package:own/sales/pages/summery_page.dart';
import 'package:own/sales/widget/recent_order.dart';
import 'package:own/sales/widget/summery_card.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final stats = dashboardProvider.salesStats;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Row(
            children: [
              Text("logout"),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login1()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: dashboardProvider.isLoadingStats
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Summary Cards (real data)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        children: [
                          SummaryCard(
                            title: 'Order form',
                            value: "${stats?['pendingOrders'] ?? 0}",
                            icon: Icons.hourglass_top_rounded,
                            iconColor: AppColors.pendingStatus,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalesOrderPage(),
                                ),
                              );
                            },
                          ),
                          SummaryCard(
                            title: 'Orders',
                            value: "${stats?['sentOrders'] ?? 0}",
                            icon: Icons.local_shipping_outlined,
                            iconColor: AppColors.sentStatus,
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalesListPage(),
                                ),
                              );
                              {
                                QuerySnapshot snapshot = await FirebaseFirestore
                                    .instance
                                    .collection("sales")
                                    .get();

                                for (var doc in snapshot.docs) {
                                  var data = doc.data() as Map<String, dynamic>;

                                  String? waybill = data["trackingNumber"];

                                  if (waybill != null && waybill.isNotEmpty) {
                                    String? status = await CurfoxService()
                                        .getCurrentStatus(waybill);

                                    if (status != null) {
                                      await FirebaseFirestore.instance
                                          .collection("sales")
                                          .doc(doc.id)
                                          .update({
                                            "courierStatus": status,
                                            "courierUpdated":
                                                FieldValue.serverTimestamp(),
                                          });
                                    }
                                  }
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Courier statuses updated"),
                                  ),
                                );
                              }
                            },
                          ),
                          SummaryCard(
                            title: 'Total Orders',
                            value: "${stats?['totalOrders'] ?? 0}",
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SummeryPage(),
                                ),
                              );
                            },
                          ),
                          SummaryCard(
                            title: "Stock Balance",
                            value: "2",
                            icon: Icons.card_giftcard,
                            iconColor: AppColors.cardBackground,
                            onTap: () {
                              context.pushNamed("cardPage");
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Recent Orders Section
                      Text('Recent Orders'),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboardProvider.recentOrders.length,
                        itemBuilder: (context, index) {
                          return RecentOrderItem(
                            order: dashboardProvider.recentOrders[index],
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
