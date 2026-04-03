import 'package:go_router/go_router.dart';
import 'package:own/login/login_page_state.dart';
import 'package:own/dashboard.dart';
import 'package:own/sales/pages/stock/stock.dart';
import 'package:own/sales/pages/stock/transaction_page.dart';
import 'package:own/sales/pages/summery_page.dart';

class RouterClass {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: "login",
        builder: (context, state) => const Login1(),
      ),

      GoRoute(
        path: "/dashboard",
        name: "dashboard",
        builder: (context, state) {
          return const DashboardPage();
        },
      ),
      GoRoute(
        path: "/summery",
        name: "summery",
        builder: (context, state) {
          return const SummeryPage();
        },
      ),
      GoRoute(
        path: "/stock",
        name: "stock",
        builder: (context, state) {
          return const StockPage();
        },
        routes: [
          GoRoute(
            path: 'transaction',
            name: 'transaction',
            builder: (context, state) => TransactionPage(),
          ),
        ],
      ),
    ],
  );
}
