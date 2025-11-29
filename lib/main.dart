import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

void main() {
  //  Add your publishableKey👇👇👇👇👇👇👇
  Stripe.publishableKey = '';
  Stripe.merchantIdentifier = 'LingoBuzz';

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  bool isProcessingPayment = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  makeApplePayPayment();
                },
                child: Text("Add Apple Pay "),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create Payment Intent
  Future<Map<String, dynamic>?> createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      // Calculate amount in cents
      int amountInCents = (double.parse(amount) * 100).toInt();

      Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          ///
          'Authorization':
              // Add your secretKey👇👇👇👇👇
              'Bearer ${''}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Error: ${response.body}');
        return null;
      }
    } catch (err) {
      debugPrint('❌ Error creating payment intent: $err');
      return null;
    }
  }

  // Make Apple Pay Payment
  Future<void> makeApplePayPayment({String? selectedPrice}) async {
    if (isProcessingPayment) return;

    try {
      isProcessingPayment = true;

      // Use the selected plan price or default
      String price = '5.59';

      debugPrint('🍎 Creating Apple Pay payment for \$$price');

      // Step 1: Check if Apple Pay is supported
      final isApplePaySupported = await Stripe.instance
          .isPlatformPaySupported();
      if (!isApplePaySupported) {
        throw Exception('Apple Pay is not supported on this device');
      }

      // Step 2: Create Payment Intent
      final paymentIntent = await createPaymentIntent(price, 'USD');

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }
      debugPrint('✅ Payment Intent created: ${paymentIntent['id']}');

      // Step 3: Present and Confirm Apple Pay Payment
      final result = await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: paymentIntent['client_secret'],
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'US',
            currencyCode: 'usd',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: 'Monthly Plan',
                amount: price,
              ),
            ],
          ),
        ),
      );

      debugPrint('✅ Apple Pay payment successful! Status: ${result.status}');
      //
    } on StripeException catch (e) {
      debugPrint('❌ Stripe Error: ${e.error.localizedMessage}');
      if (e.error.code != FailureCode.Canceled) {}
    } catch (e) {
      debugPrint('❌ Apple Pay payment failed: $e');
    } finally {
      isProcessingPayment = false;
    }
  }
}
