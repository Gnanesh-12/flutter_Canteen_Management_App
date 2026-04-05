import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/constants.dart';
import 'web_checkout_stub.dart' if (dart.library.js) 'web_checkout.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentFailureCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

class PaymentService {
  late Razorpay _razorpay;
  final String _apiKey = AppConstants.razorpayKey;
  
  late PaymentSuccessCallback _onSuccess;
  late PaymentFailureCallback _onFailure;

  void init({
    required PaymentSuccessCallback onSuccess,
    required PaymentFailureCallback onFailure,
    required ExternalWalletCallback onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    }
  }

  void _onWebSuccess(dynamic response) {
    // Convert JS response to PaymentSuccessResponse
    _onSuccess(PaymentSuccessResponse(
      response['razorpay_payment_id'],
      response['razorpay_order_id'],
      response['razorpay_signature'],
      {}, // Added missing 4th argument (data map)
    ));
  }

  void _onWebFailure(dynamic response) {
    _onFailure(PaymentFailureResponse(
      response['code'] ?? 0,
      response['description'] ?? 'Payment Failed',
      null,
    ));
  }

  void openCheckout({
    required double amount,
    required String contactEmail,
    required String contactPhone,
  }) {
    var options = {
      'key': _apiKey,
      'amount': (amount * 100).toInt(), // amount in paise
      'name': 'Amrita Canteen',
      'description': 'Order Payment',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contactPhone,
        'email': contactEmail,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      if (kIsWeb) {
        openWebCheckout(
          options,
          onSuccess: _onWebSuccess,
          onFailure: _onWebFailure,
        );
      } else {
        _razorpay.open(options);
      }
    } catch (e) {
      debugPrint('Error opening checkout: $e');
    }
  }

  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
  }
}
