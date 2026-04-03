import 'package:flutter/material.dart';
import 'package:own/goRouter/router.dart';
import 'package:own/provider/dashboard_provider.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardProvider()
            ..listenToRecentOrders()
            ..fetchSalesStatistics(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Own',
        debugShowCheckedModeBanner: false,
        routerConfig: RouterClass().router,
      ),
    );
  }
}
