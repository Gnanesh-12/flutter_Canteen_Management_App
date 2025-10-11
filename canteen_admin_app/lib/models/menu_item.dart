import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMenuItem {
  final String? id;
  final String name;
  final double price;
  final String category;
  int stock;

  AdminMenuItem({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
  });

  // Factory constructor to create a MenuItem from a Firestore document
  factory AdminMenuItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AdminMenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      stock: data['stock'] ?? 0,
    );
  }

  // Method to convert a MenuItem to a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'stock': stock,
    };
  }
}