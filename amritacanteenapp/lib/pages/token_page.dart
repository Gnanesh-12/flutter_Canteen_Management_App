import 'package:flutter/material.dart';
import 'canteen_selection_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TokenPage extends StatefulWidget {
  final String userName;
  final String rollNumber;
  final String orderId;
  final int tokenNumber;

  const TokenPage({
    super.key,
    required this.userName,
    required this.rollNumber,
    required this.orderId,
    required this.tokenNumber,
  });

  @override
  _TokenPageState createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("Waiting for order confirmation..."));
          }

          var orderData = snapshot.data!.data() as Map<String, dynamic>;
          String status = orderData['status'] ?? 'Preparing';

          bool isDelivered = (status == 'Ready');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                    },
                    child: isDelivered 
                        ? _buildDeliveredContent() 
                        : _buildTokenContent(),
                  ),
                  const Spacer(),
                  if (isDelivered)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const CanteenSelectionPage()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A1038),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Place New Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTokenContent() {
    return Column(
      key: const ValueKey('token'),
      children: [
         const Icon(Icons.check_circle, color: Colors.green, size: 80),
         const SizedBox(height: 20),
         const Text(
          'Payment Successful!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 30),
        const Text(
          'YOUR TOKEN NUMBER',
          style: TextStyle(fontSize: 16, color: Colors.black54, letterSpacing: 1),
        ),
        Text(
          '${widget.tokenNumber}',
          style: const TextStyle(fontSize: 100, color: Color(0xFF8A1038), fontWeight: FontWeight.w900),
        ),
         const SizedBox(height: 20),
         const Text(
          'Your order is being prepared...',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildDeliveredContent() {
    return Column(
      key: const ValueKey('delivered'),
      children: [
        const Icon(Icons.restaurant_menu, color: Color(0xFF8A1038), size: 80),
        const SizedBox(height: 20),
        const Text(
          'Order Ready!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        const Text(
          'Please collect your order from the counter.',
           style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 30),
         Text(
          'TOKEN NO: ${widget.tokenNumber}',
          style: const TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '${widget.userName} / ${widget.rollNumber}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        )
      ],
    );
  }
}
