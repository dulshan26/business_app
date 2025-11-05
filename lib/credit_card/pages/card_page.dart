import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:own/credit_card/providers/balance_provider.dart';
import 'package:own/credit_card/widget/card.dart';
import 'package:own/credit_card/widget/floating_action.dart';
import 'package:own/firebase/firestore.dart';
import 'package:provider/provider.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  final FirestoreService service = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final balanceProvider = Provider.of<BalanceProvider>(
        context,
        listen: false,
      );
      balanceProvider.listenToBalace('HNB');
      balanceProvider.listenToBalace('DFCC');
      balanceProvider.listenToBalace('Pan Asia');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Consumer<BalanceProvider>(
          builder: (context, provider, child) {
            return Container(
              color: Colors.grey[200],
              width: double.infinity,

              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.goNamed("dashboard");
                        },
                        child: Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "Credit Cards Management",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("manage your credit cards transaction easily"),

                  GestureDetector(
                    child: CardContainer(
                      title: "HNB",
                      subtitle: "Outstanding Balance",
                      amount: provider.getbalance("HNB"),
                    ),
                    onTap: () {
                      context.goNamed('hnb');
                    },
                  ),
                  GestureDetector(
                    child: CardContainer(
                      title: "DFCC",
                      subtitle: "Outstanding Balance",
                      amount: provider.getbalance("DFCC"),
                    ),
                    onTap: () {
                      context.goNamed('dfcc');
                    },
                  ),
                  GestureDetector(
                    child: CardContainer(
                      title: "Pan Asia",
                      subtitle: "Outstanding Balance",
                      amount: provider.getbalance("Pan Asia"),
                    ),
                    onTap: () {
                      context.goNamed('pan_asia');
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Floating(),
    );
  }
}
