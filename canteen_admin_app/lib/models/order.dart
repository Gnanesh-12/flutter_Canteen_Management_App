import 'package:cloud_firestore/cloud_firestore.dart';

class AppOrder {
  final String id;
  final String userName;
  final String rollNumber;
  final double totalAmount;
  final List<dynamic> items;
  final String status;
  final DateTime? timestamp;
  final int tokenNumber;

  AppOrder({
    required this.id,
    required this.userName,
    required this.rollNumber,
    required this.totalAmount,
    required this.items,
    required this.status,
    this.timestamp,
    required this.tokenNumber,
  });

  factory AppOrder.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppOrder(
      id: doc.id,
      userName: data['userName'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      items: data['items'] ?? [],
      status: data['status'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      tokenNumber: data['tokenNumber'] ?? 0,
    );
  }
}
