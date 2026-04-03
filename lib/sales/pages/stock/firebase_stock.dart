import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseStock {
  final stockCollection = FirebaseFirestore.instance.collection('stock');

  Future<void> recordTransaction({
    required String stockDocId,
    required String itemName,
    required int quantity,
    required String type, // "in" or "out"
    String? note,
  }) async {
    final docRef = stockCollection.doc(stockDocId);
    final txRef = docRef.collection("transactions").doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Stock item not found");

      final currentBalance = (snapshot['balance'] ?? 0) as int;
      int newBalance = currentBalance;

      if (type == "in") {
        newBalance += quantity;
      } else if (type == "out") {
        newBalance -= quantity;

        if (newBalance < 0) {
          throw Exception("Not enough stock");
        }
      }

      // Update stock balance
      transaction.update(docRef, {'balance': newBalance});

      // Save transaction inside SUBCOLLECTION
      transaction.set(txRef, {
        'quantity': quantity,
        'type': type,
        'note': note ?? "",
        'item_name': itemName,
        'timestamp': FieldValue.serverTimestamp(),
        'balance_after': newBalance,
      });
    });
  }
}
