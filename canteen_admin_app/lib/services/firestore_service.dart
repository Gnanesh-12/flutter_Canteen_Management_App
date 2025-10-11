import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Order Methods ---
  Stream<QuerySnapshot> getOrdersStream(String canteenId) {
    return _db
        .collection('orders')
        .where('canteenId', isEqualTo: canteenId)
        .where('status', isEqualTo: 'Preparing') // Only fetch pending orders
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) {
    return _db.collection('orders').doc(orderId).update({'status': newStatus});
  }

  // --- Canteen Status Method (This was missing) ---
  Future<void> updateCanteenStatus(String canteenId, bool isOpen) {
    return _db.collection('canteens').doc(canteenId).update({'isOpen': isOpen});
  }

  // --- Menu Management Methods ---
  Stream<DocumentSnapshot> getCanteenStream(String canteenId) {
    return _db.collection('canteens').doc(canteenId).snapshots();
  }

  Stream<QuerySnapshot> getMenuItemsStream(String canteenId, String category) {
    return _db
        .collection('canteens')
        .doc(canteenId)
        .collection('menu_items')
        .where('category', isEqualTo: category)
        .snapshots();
  }

  Future<void> addMenuItem(String canteenId, AdminMenuItem item) {
    return _db
        .collection('canteens')
        .doc(canteenId)
        .collection('menu_items')
        .add(item.toJson());
  }

  Future<void> updateMenuItem(String canteenId, AdminMenuItem item) {
    return _db
        .collection('canteens')
        .doc(canteenId)
        .collection('menu_items')
        .doc(item.id)
        .update(item.toJson());
  }

  Future<void> deleteMenuItem(String canteenId, String itemId) {
    return _db
        .collection('canteens')
        .doc(canteenId)
        .collection('menu_items')
        .doc(itemId)
        .delete();
  }

  Future<void> addCategory(String canteenId, String category) {
    return _db.collection('canteens').doc(canteenId).update({
      'categories': FieldValue.arrayUnion([category])
    });
  }

  Future<void> deleteCategory(String canteenId, String category) {
    return _db.collection('canteens').doc(canteenId).update({
      'categories': FieldValue.arrayRemove([category])
    });
  }
}
