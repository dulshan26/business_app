import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;

  final List<String> images;

  final String category;
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    required this.category,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'images': images,
      'category': category,
      'isActive': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ItemModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    return ItemModel(
      id: snap.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
      category: data['category'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
