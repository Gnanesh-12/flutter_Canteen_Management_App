// lib/services/razorpay_web_interop.dart
@JS()
library razorpay_web;

import 'package:js/js.dart';

@JS('Razorpay')
class RazorpayWeb {
  external RazorpayWeb(dynamic options);
  external void open();
  external void on(String event, Function callback);
}
