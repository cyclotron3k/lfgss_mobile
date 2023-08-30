import 'package:flutter/material.dart';

class LoginToSee extends StatelessWidget {
  final String what;
  final Icon icon;
  const LoginToSee({
    super.key,
    required this.what,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Login to see $what",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          icon,
        ],
      ),
    );
  }
}
