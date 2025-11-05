import 'package:flutter/material.dart';
import 'package:own/credit_card/providers/balance_provider.dart';
import 'package:own/credit_card/widget/balance.dart';
import 'package:own/credit_card/widget/floating_action.dart';
import 'package:own/firebase/firestore.dart';
import 'package:provider/provider.dart';

class HnbCard extends StatefulWidget {
  const HnbCard({super.key});
  @override
  State<HnbCard> createState() => _HnbCardState();
}

class _HnbCardState extends State<HnbCard> {
  final FirestoreService servi = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final balanceProvider = Provider.of<BalanceProvider>(
        context,
        listen: false,
      );
      balanceProvider.listenToBalace('HNB'); // correct name
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HNB Card Details")),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Consumer<BalanceProvider>(
              builder: (context, provider, child) {
                final hnbBalance = provider.getbalance('HNB');
                return Balance(cardName: 'HNB', amount: hnbBalance);
              },
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: servi.getTransactionsByCard("HNB"),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions'));
                }
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
                        (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                    final type = transaction['type'] as String? ?? 'expense';
                    final holder = transaction['holder'] as String? ?? '';
                    final id = transaction['id'] as String?;
                    return ListTile(
                      leading: Icon(
                        type == 'Cash Credit'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: type == 'Cash Credit'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(description),
                      subtitle: Text(
                        '${holder.isNotEmpty ? '$holder • ' : ''}$date',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LKR ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: type == 'Cash Credit'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: id == null
                                ? null
                                : () async {
                                    await servi.deleteTransaction(id);
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
      floatingActionButton: Floating(),
    );
  }
}
