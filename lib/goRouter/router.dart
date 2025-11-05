import 'package:go_router/go_router.dart';
import 'package:own/credit_card/pages/card_page.dart';
import 'package:own/credit_card/pages/card_page/dfcc.dart';
import 'package:own/credit_card/pages/card_page/hnb.dart';
import 'package:own/credit_card/pages/card_page/pan_asia.dart';
import 'package:own/login/login_page_state.dart';
import 'package:own/dashboard.dart';
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
        path: "/card_details",
        name: "cardPage",
        builder: (context, state) {
          return const CardsPage();
        },
        //nested routers can be added here
        routes: [
          GoRoute(
            path: 'hnb',
            name: 'hnb',
            builder: (context, state) => const HnbCard(),
          ),
          GoRoute(
            path: 'dfcc',
            name: 'dfcc',
            builder: (context, state) => const DFCCcard(),
          ),
          GoRoute(
            path: 'pan_asia',
            name: 'pan_asia',
            builder: (context, state) => const PanAsia(),
          ),
        ],
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
    ],
  );
}
