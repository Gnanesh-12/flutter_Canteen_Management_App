import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSetupService {
  static Future<void> initializeAdmins(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final List<Map<String, String>> admins = [
      {
        'email': 'it_admin@amrita.edu',
        'password': 'Admin@it123',
        'canteenId': 'it_canteen',
        'name': 'IT Canteen Admin',
      },
      {
        'email': 'main_admin@amrita.edu',
        'password': 'Admin@main123',
        'canteenId': 'main_canteen',
        'name': 'Main Canteen Admin',
      },
      {
        'email': 'mba_admin@amrita.edu',
        'password': 'Admin@mba123',
        'canteenId': 'mba_canteen',
        'name': 'MBA Canteen Admin',
      },
    ];

    try {
      for (var admin in admins) {
        // 1. Create User in Firebase Auth
        UserCredential? userCredential;
        try {
          userCredential = await auth.createUserWithEmailAndPassword(
            email: admin['email']!,
            password: admin['password']!,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
             debugPrint('Admin ${admin['email']} already exists in Auth.');
             // We still try to update Firestore in case it's missing
          } else {
            rethrow;
          }
        }

        // 2. Store Admin Details in Firestore
        // We use a specific collection 'admin_details' as requested
        await firestore.collection('admin_details').doc(admin['email']).set({
          'email': admin['email'],
          'canteenId': admin['canteenId'],
          'name': admin['name'],
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Successfully initialized admin: ${admin['email']}');
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All 3 Admins successfully initialized!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error in Admin Initialization: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing admins: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
