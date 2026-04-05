import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import 'canteen_selection_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  StreamSubscription? _ordersSubscription;
  final Set<String> _notifiedOrderIds = {};

  final List<Widget> _pages = [
    const CanteenSelectionPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() async {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermission();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool isInitialLoad = true;
      _ordersSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Ready')
          .snapshots()
          .listen((snapshot) {
        if (isInitialLoad) {
          for (var change in snapshot.docChanges) {
            _notifiedOrderIds.add(change.doc.id);
          }
          isInitialLoad = false;
          return;
        }

        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
            final orderId = change.doc.id;
            if (!_notifiedOrderIds.contains(orderId)) {
              _notifiedOrderIds.add(orderId);
              notificationService.showNotification(
                id: orderId.hashCode,
                title: 'Order Ready!',
                body: 'Your order is ready to be collected.',
              );
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_list),
              activeIcon: Icon(CupertinoIcons.square_list_fill),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_solid),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
