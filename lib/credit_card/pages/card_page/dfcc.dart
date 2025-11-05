import 'package:flutter/material.dart';
import 'package:own/credit_card/providers/balance_provider.dart';
import 'package:own/credit_card/widget/balance.dart';
import 'package:own/credit_card/widget/floating_action.dart';

import 'package:own/firebase/firestore.dart';
import 'package:provider/provider.dart';

class DFCCcard extends StatelessWidget {
  const DFCCcard({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService servi = FirestoreService();

    final balanceProvider = Provider.of<BalanceProvider>(
      context,
      listen: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      balanceProvider.listenToBalace('DFCC');
    });
    return Scaffold(
      appBar: AppBar(title: const Text("DFCC Card Details")),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Consumer<BalanceProvider>(
              builder: (context, provider, child) {
                final dfccBalance = provider.getbalance('DFCC');
                return Balance(cardName: 'DFCC', amount: dfccBalance);
              },
            ),
            Container(
              color: Colors.grey[200],
              width: double.infinity,
              child: Column(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: servi.getTransactionsByCard("DFCC"),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final transactions = snapshot.data ?? [];
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final date = transaction['date'] as String? ?? '';
                          final description =
                              transaction['description'] as String? ?? '';
                          final amount =
                              (transaction['amount'] as num?)?.toDouble() ??
                              0.0;
                          final type =
                              transaction['type'] as String? ?? 'expense';
                          return ListTile(
                            leading: Icon(
                              type == 'income'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(description),
                            subtitle: Text(date),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: type == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await servi.deleteTransaction(
                                      transaction['id'] as String,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Floating(),
    );
  }
}
