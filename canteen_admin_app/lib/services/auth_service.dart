import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _canteenId;

  // Stream for listening to auth state changes in the UI
  Stream<User?> get user => _auth.authStateChanges();

  // Getter for synchronously accessing the current user
  User? get currentUser => _auth.currentUser;

  String? get canteenId => _canteenId;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchCanteenId(user.email ?? '');
      } else {
        _canteenId = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchCanteenId(String email) async {
    try {
      final doc = await _firestore.collection('admin_details').doc(email).get();
      if (doc.exists) {
        _canteenId = doc.get('canteenId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching canteenId: $e');
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _fetchCanteenId(email);
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message);
      return null;
    }
  }

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message);
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _canteenId = null;
    notifyListeners();
  }
}
