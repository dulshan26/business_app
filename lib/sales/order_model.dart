// lib/models/order_model.dart

enum OrderStatus { pending, sent, cashCollect, cancel }

class Order {
  final String id;
  final String customerName;
  final double amount;
  final OrderStatus status;
  final String phone;

  Order({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.phone,
  });

  // ✅ Factory to create Order from Firestore Map
  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      id: data['id'] ?? '',
      customerName: data['customerName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: _statusFromString(data['status']),
      phone: data['phone'] ?? '0',
    );
  }

  // ✅ Convert Order to Map (for saving back to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'amount': amount,
      'status': status.toString().split('.').last,
    };
  }

  // Helper to parse status safely
  static OrderStatus _statusFromString(String? status) {
    switch (status) {
      case 'Pending':
        return OrderStatus.pending;
      case 'Sent':
        return OrderStatus.sent;
      case 'CashCollect':
        return OrderStatus.cashCollect;
      case ' Cancel':
        return OrderStatus.cancel;
      default:
        return OrderStatus.cancel;
    }
  }
}

// Simple Item model
class ItemModel {
  final String id;
  final String name;
  int quantity;

  ItemModel({required this.id, required this.name, this.quantity = 0});

  //save from the firebase
  factory ItemModel.fromMap(Map<String, dynamic> data, String docId) {
    return ItemModel(
      id: docId,
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? '',
    );
  }
  //data read form firebase
  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity};
  }
}
