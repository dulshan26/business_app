import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BalanceProvider with ChangeNotifier {
  final Map<String, double> _totalbalance = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _listeners = {};

  double getbalance(String cardName) => _totalbalance[cardName] ?? 0.00;

  void listenToBalace(String cardName) {
    _listeners[cardName]?.cancel();

    _listeners[cardName] = FirebaseFirestore.instance
        .collection('credit_card')
        .where('card', isEqualTo: cardName)
        .snapshots()
        .listen((snapshot) {
          double sum = 0.00;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final balance = data['amount'];
            final type = data['type'];
            if (balance != null) {
              double amount = (balance as num).toDouble();
              if (type == 'Monthly bill') {
                sum += amount;
              } else {
                sum -= amount;
              }
            }
          }
          _totalbalance[cardName] = sum;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    for (var subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
    super.dispose();
  }
}
