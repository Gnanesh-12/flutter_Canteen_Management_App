import 'package:canteen_admin_app/services/auth_service.dart';
import 'package:canteen_admin_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  String getCanteenId(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final email = user?.email ?? '';

    if (email.startsWith('it-canteen-admin')) {
      return 'it_canteen';
    } else if (email.startsWith('main-canteen-admin')) {
      return 'main_canteen';
    } else if (email.startsWith('mba-canteen-admin')) {
      return 'mba_canteen';
    }
    return 'default_canteen';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final canteenId = getCanteenId(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.getCanteenStream(canteenId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Canteen data not found.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        // Default to 'false' (closed) if the field doesn't exist
        final bool isOpen = data['isOpen'] ?? false;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              child: SwitchListTile(
                title: const Text('Canteen Open', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(isOpen ? 'Users can place new orders.' : 'Users cannot place new orders.'),
                value: isOpen,
                onChanged: (bool value) {
                  firestoreService.updateCanteenStatus(canteenId, value);
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
