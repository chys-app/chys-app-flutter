import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentView extends StatelessWidget {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text("Payment View"),
          CardFormField(
            dangerouslyGetFullCardDetails: true,
            dangerouslyUpdateFullCardDetails: true,
            style: CardFormStyle(
                placeholderColor: Colors.white,
                borderColor: Colors.white,
                textColor: Colors.white,
                cursorColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
