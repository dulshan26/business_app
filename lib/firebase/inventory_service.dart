import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📦 Stock එකට බඩු එනකොට (In) හෝ විකිනෙනකොට (Out) Transaction එකක් ලියන Function එක
  Future<void> recordStockTransaction({
    required String productId, // e.g., "ykSGfVFFQaZSZzDZJrIe"
    required String
    itemName, // e.g., "Display mobile router" (Dynamic ලෙස ලබාදීමට)
    required int itemQuantity, // e.g., 5
    required int currentBalance, // e.g., 28
    required String transactionType, // "in" හෝ "out"
    String transactionNote = "",
  }) async {
    // 1. අලුත් Balance එක ගණනය කිරීම
    int newBalance = transactionType == "out"
        ? currentBalance - itemQuantity
        : currentBalance + itemQuantity;

    // 2. References සකසා ගැනීම
    DocumentReference productRef = _db.collection('stock').doc(productId);
    CollectionReference transRef = productRef.collection('transactions');

    // 3. Firestore WriteBatch එකක් පාවිච්චි කිරීම (වැඩ දෙකම එක පාර සිදුවීමට)
    WriteBatch batch = _db.batch();

    // A. Sub-collection එක ඇතුලට අලුත් Transaction එකක් දැමීම
    // .doc() එකට ID එකක් නොදුන් විට Firestore විසින්ම අලුත් ID එකක් සාදා ගනී
    DocumentReference newTransRef = transRef.doc();
    batch.set(newTransRef, {
      'quantity': itemQuantity,
      'balance_after': newBalance,
      'type': transactionType,
      'note': transactionNote,
      'timestamp': FieldValue.serverTimestamp(),
      'item_name': itemName,
    });

    // B. ප්‍රධාන Product Document එකේ දැනට තියෙන balance එක update කිරීම
    batch.update(productRef, {
      'balance': newBalance, // ඔයාගේ database එකේ field එක 'balance' නිසා
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 4. Updates දෙකම එකවරම Database එකට යැවීම
    try {
      SnackBar(content: Text("Updating stock..."));
      await batch.commit();
    } catch (e) {
      SnackBar(content: Text("Error recording stock transaction: $e"));
      rethrow; // App එකට error එක පෙන්වීමට අවශ්‍ය නම්
    }
  }
}
