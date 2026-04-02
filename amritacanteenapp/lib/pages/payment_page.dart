import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';
import 'token_page.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final String canteenId;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    required this.canteenId,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _upiController = TextEditingController(text: 'example@upi');
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final cart = context.read<CartModel>();
    final firestore = FirebaseFirestore.instance;

    try {
      String? orderId;
      int? token;

      // Use a Firestore transaction to ensure atomic operations (all or nothing)
      await firestore.runTransaction((transaction) async {
        final List<DocumentSnapshot> itemSnapshots = [];
        final Map<String, int> itemQuantities = {};

        // Prepare to fetch all menu items in the cart
        for (var cartItem in cart.items) {
          final itemRef = firestore
              .collection('canteens')
              .doc(widget.canteenId)
              .collection('menu_items')
              .doc(cartItem.menuItem.id);
          
          final itemSnap = await transaction.get(itemRef);
          itemSnapshots.add(itemSnap);
          itemQuantities[cartItem.menuItem.id] = cartItem.quantity;
        }

        // Validate stock for all items BEFORE creating the order
        for (var itemSnap in itemSnapshots) {
          if (!itemSnap.exists) {
            final itemName = cart.items.firstWhere((item) => item.menuItem.id == itemSnap.id).menuItem.name;
            throw Exception("'$itemName' is no longer available.");
          }

          final data = itemSnap.data() as Map<String, dynamic>;

          // Safely get current stock, ensuring it's a number
          final currentStockValue = data['stock'];
          if (currentStockValue is! num) {
            throw Exception("Stock data for '${data['name']}' is invalid or missing.");
          }
          final currentStock = currentStockValue.toInt();

          // Safely get the quantity requested from our map
          final requestedQuantity = itemQuantities[itemSnap.id];
          if (requestedQuantity == null) {
            throw Exception("A logic error occurred: Could not find quantity for '${data['name']}'.");
          }
          
          // Final check: is there enough stock?
          if (currentStock < requestedQuantity) {
            final itemName = data['name'];
            throw Exception(
                "Not enough stock for $itemName. Only $currentStock left.");
          }
        }

        // If all validation passes, loop again to update the stock
        for (var itemSnap in itemSnapshots) {
          // These operations are now safe because of the checks above
          final currentStock = (itemSnap.get('stock') as num).toInt();
          final requestedQuantity = itemQuantities[itemSnap.id]!;
          
          // This is the corrected and safe implementation of the line you pointed out
          final newStock = currentStock - requestedQuantity;
          transaction.update(itemSnap.reference, {'stock': newStock});
        }

        // All checks passed, create the order
        token = Random().nextInt(900) + 100;
        final orderData = {
          'userName': _nameController.text.trim(),
          'rollNumber': _rollNumberController.text.trim(),
          'upiId': _upiController.text.trim(),
          'totalAmount': widget.totalAmount,
          'items': cart.items
              .map((item) => {
                    'name': item.menuItem.name,
                    'quantity': item.quantity,
                    'price': item.menuItem.price,
                  })
              .toList(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Preparing',
          'canteenId': widget.canteenId,
          'tokenNumber': token,
          'userId': FirebaseAuth.instance.currentUser?.uid,
        };

        final newOrderRef = firestore.collection('orders').doc();
        transaction.set(newOrderRef, orderData);
        orderId = newOrderRef.id;
      });

      // If the transaction completes successfully
      cart.clearCart();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TokenPage(
              userName: _nameController.text,
              rollNumber: _rollNumberController.text,
              orderId: orderId!,
              tokenNumber: token!,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // If the transaction fails for any reason (e.g., out of stock)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Payment Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8A1038),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isProcessing ? _buildProcessingScreen() : _buildDetailsForm(),
      ),
    );
  }

  Widget _buildDetailsForm() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text('Total Amount to Pay',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 40),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (value) =>
                  value!.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _rollNumberController,
              decoration: const InputDecoration(
                  labelText: 'Roll Number', border: OutlineInputBorder()),
              validator: (value) =>
                  value!.trim().isEmpty ? 'Please enter your roll number' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _upiController,
              decoration: const InputDecoration(
                  labelText: 'UPI ID', border: OutlineInputBorder()),
              validator: (value) =>
                  value!.trim().isEmpty ? 'Please enter your UPI ID' : null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A1038),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('PAY NOW',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Container(
      key: const ValueKey('processing'),
      color: const Color(0xFF8A1038),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 30),
            const Text(
              'Processing Order...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Validating stock and confirming payment...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

