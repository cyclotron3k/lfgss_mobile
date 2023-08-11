import 'package:flutter/material.dart';

import '../models/huddles.dart';
import 'huddles_screen.dart';

class FutureHuddlesScreen extends StatefulWidget {
  final Future<Huddles> huddles;
  const FutureHuddlesScreen({super.key, required this.huddles});

  @override
  State<FutureHuddlesScreen> createState() => _FutureHuddlesScreenState();
}

class _FutureHuddlesScreenState extends State<FutureHuddlesScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Huddles>(
      future: widget.huddles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return HuddlesScreen(huddles: snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64.0,
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
