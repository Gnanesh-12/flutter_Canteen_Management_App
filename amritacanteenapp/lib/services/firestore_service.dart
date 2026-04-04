import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveOrder(OrderModel order) async {
    try {
      await _db.collection('orders').add(order.toMap());
    } catch (e) {
      throw Exception('Failed to save order to Firestore: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    }
    return {};
  }
}
