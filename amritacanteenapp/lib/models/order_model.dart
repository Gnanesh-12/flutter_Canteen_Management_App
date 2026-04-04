import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class OrderModel {
  final String? id;
  final String userId;
  final String userName;
  final String rollNumber;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentId;
  final String status;
  final DateTime timestamp;
  final String canteenId;
  final int tokenNumber;

  OrderModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.rollNumber,
    required this.items,
    required this.totalAmount,
    required this.paymentId,
    this.status = 'paid',
    required this.timestamp,
    required this.canteenId,
    required this.tokenNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rollNumber': rollNumber,
      'items': items.map((item) => {
        'name': item.menuItem.name,
        'quantity': item.quantity,
        'price': item.menuItem.price,
      }).toList(),
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'canteenId': canteenId,
      'tokenNumber': tokenNumber,
    };
  }
}
