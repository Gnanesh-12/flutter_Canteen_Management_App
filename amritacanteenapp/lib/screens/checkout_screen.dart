import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import '../pages/token_page.dart';
import '../config/constants.dart';

class CheckoutScreen extends StatefulWidget {
  final String canteenId;

  const CheckoutScreen({super.key, required this.canteenId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentService _paymentService = PaymentService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _firestoreService.getUserProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    final cart = context.read<CartModel>();
    final user = FirebaseAuth.instance.currentUser;

    try {
      final token = Random().nextInt(900) + 100;
      final order = OrderModel(
        userId: user?.uid ?? 'unknown',
        userName: _userProfile['name'] ?? 'User',
        rollNumber: _userProfile['rollnumber'] ?? 'N/A',
        items: List.from(cart.items),
        totalAmount: cart.totalPrice,
        paymentId: response.paymentId ?? 'N/A',
        timestamp: DateTime.now(),
        canteenId: widget.canteenId,
        tokenNumber: token,
      );

      await _firestoreService.saveOrder(order);
      cart.clearCart();

      Fluttertoast.showToast(
        msg: "Payment Successful!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TokenPage(
              userName: order.userName,
              rollNumber: order.rollNumber,
              orderId: 'TBD', // Firestore ID isn't returned by .add() easily here
              tokenNumber: order.tokenNumber,
            ),
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving order: $e", backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.message}",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
  }

  void _startPayment() {
    final cart = context.read<CartModel>();
    final user = FirebaseAuth.instance.currentUser;

    if (cart.items.isEmpty) {
      Fluttertoast.showToast(msg: "Cart is empty!");
      return;
    }

    _paymentService.openCheckout(
      amount: cart.totalPrice,
      contactEmail: user?.email ?? 'user@example.com',
      contactPhone: '9999999999', // Placeholder
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF8A1038),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (AppConstants.razorpayKey == 'rzp_test_YOUR_ACTUAL_KEY')
                  Container(
                    width: double.infinity,
                    color: Colors.amber.shade100,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(child: const Text('Razorpay Key is not configured. Please update Constants.dart.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(item.menuItem.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Quantity: ${item.quantity}'),
                          trailing: Text('₹${(item.menuItem.price * item.quantity).toStringAsFixed(2)}'),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            Text('₹${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8A1038))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _startPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A1038),
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text('Pay Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
