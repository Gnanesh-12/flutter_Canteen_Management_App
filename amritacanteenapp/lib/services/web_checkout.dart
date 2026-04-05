// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js' as js;
import 'package:js/js_util.dart' as js_util;

void openWebCheckout(
  Map<String, dynamic> options, {
  required Function(dynamic) onSuccess,
  required Function(dynamic) onFailure,
}) {
  var razorpay = js.context['Razorpay'];
  if (razorpay == null) {
    onFailure({'code': 0, 'description': 'Error loading Razorpay checkout'});
    return;
  }

  var finalOptions = {
    ...options,
    'handler': js.allowInterop((response) {
      if (response != null) {
        var data = {
          'razorpay_payment_id': js_util.getProperty(response, 'razorpay_payment_id'),
          'razorpay_order_id': js_util.getProperty(response, 'razorpay_order_id'),
          'razorpay_signature': js_util.getProperty(response, 'razorpay_signature'),
        };
        onSuccess(data);
      } else {
        onSuccess({});
      }
    }),
  };

  var jsOptions = js.JsObject.jsify(finalOptions);
  var rzp = js.JsObject(razorpay, [jsOptions]);

  rzp.callMethod('on', [
    'payment.failed',
    js.allowInterop((response) {
      if (response != null) {
        var error = js_util.getProperty(response, 'error');
        if (error != null) {
          var errorData = {
            'code': js_util.getProperty(error, 'code'),
            'description': js_util.getProperty(error, 'description'),
          };
          onFailure(errorData);
        } else {
          onFailure({'code': 0, 'description': 'Payment failed'});
        }
      } else {
        onFailure({'code': 0, 'description': 'Payment failed'});
      }
    })
  ]);

  rzp.callMethod('open');
}
