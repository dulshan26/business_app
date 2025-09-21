// lib/models/order_model.dart

enum OrderStatus { Pending, Sent, CashCollect }

class Order {
  final String id;
  final String customerName;
  final double amount;
  final OrderStatus status;

  Order({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
  });
}

// Simple Item model
class ItemModel {
  final String id;
  final String name;

  ItemModel({required this.id, required this.name});
}

final List<ItemModel> itemList = [
  ItemModel(id: '1', name: 'Car dash number solar'),
  ItemModel(id: '2', name: 'Touch Pen'),
  ItemModel(id: '3', name: 'Apple pencil'),
  ItemModel(id: '4', name: 'Car Gps'),
  ItemModel(id: '5', name: 'Reverse Camera'),
  ItemModel(id: '6', name: 'Silence Mouse'),
  ItemModel(id: '7', name: 'Non Display Mobile Router'),
  ItemModel(id: '8', name: 'Cloths Folding'),
  ItemModel(id: '9', name: 'Universal Pencil'),
  ItemModel(id: '10', name: 'CHUB'),
  ItemModel(id: '11', name: 'Sinotrack'),
  ItemModel(id: '12', name: 'Nail Sticker'),
  ItemModel(id: '13', name: 'DASHCAMERA'),
  ItemModel(id: '14', name: 'Portable FAN'),
  ItemModel(id: '15', name: 'Mini temperature'),
  ItemModel(id: '16', name: 'Car Cleaner Pad'),
  ItemModel(id: '17', name: 'Mini Robo Cute'),
  ItemModel(id: '18', name: 'Car Jack'),
  ItemModel(id: '19', name: 'Nail Cleaner'),
  ItemModel(id: '20', name: 'Display mobile router'),
  ItemModel(id: '21', name: 'Mazdakey'),
  ItemModel(id: '22', name: 'Dongle Mini Mifi USB'),
  ItemModel(id: '23', name: 'Eyebrow Pencil'),
  ItemModel(id: '24', name: 'Car Multifunction'),
  ItemModel(id: '25', name: 'Bluetooth Speaker'),
  ItemModel(id: '26', name: 'Mifi Battery 2100mah'),
  ItemModel(id: '27', name: 'Unlock Router 1200mbps'),
  ItemModel(id: '28', name: 'Night Lamp Motor Bike'),
  ItemModel(id: '29', name: 'Remote table tamp'),
  ItemModel(id: '30', name: 'Nany bib'),
  ItemModel(id: '31', name: 'Power Bank Xiomi 3*18600'),
];
List<ItemModel> orderItems = [];
