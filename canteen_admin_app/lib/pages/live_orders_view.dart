import 'package:canteen_admin_app/models/order.dart';
import 'package:canteen_admin_app/services/auth_service.dart';
import 'package:canteen_admin_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LiveOrdersView extends StatelessWidget {
  const LiveOrdersView({super.key});

  String getCanteenId(BuildContext context) {
    return Provider.of<AuthService>(context, listen: false).canteenId ?? 'default_canteen';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final canteenId = authService.canteenId;

    if (canteenId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final firestoreService = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getOrdersStream(canteenId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs
            .map((doc) => AppOrder.fromFirestore(doc))
            .toList();
        
        // Sort orders by time on the client-side
        orders.sort((a, b) => (a.timestamp ?? DateTime(0)).compareTo(b.timestamp ?? DateTime(0)));


        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'No live orders for this canteen right now.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return OrderCard(order: orders[index]);
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final AppOrder order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final time = order.timestamp != null
        ? DateFormat('hh:mm a').format(order.timestamp!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Token #${order.tokenNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.userName} - ${order.rollNumber}'),
            const Divider(height: 24),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['quantity']} x ${item['name']}'),
                      Text(
                          '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green)),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                      value: 'Preparing',
                      label: Text('Preparing'),
                      icon: Icon(Icons.soup_kitchen)),
                  ButtonSegment<String>(
                      value: 'Ready',
                      label: Text('Ready'),
                      icon: Icon(Icons.check_circle)),
                ],
                selected: <String>{order.status},
                onSelectionChanged: (Set<String> newSelection) {
                  firestoreService.updateOrderStatus(order.id, newSelection.first);
                },
                 style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: const Color(0xFF8A1038),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
