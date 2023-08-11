import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/huddle_screen.dart';

import '../models/huddle.dart';

class FutureHuddleScreen extends StatefulWidget {
  final Future<Huddle> huddle;
  const FutureHuddleScreen({super.key, required this.huddle});

  @override
  State<FutureHuddleScreen> createState() => _FutureHuddleScreenState();
}

class _FutureHuddleScreenState extends State<FutureHuddleScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Huddle>(
      future: widget.huddle,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return HuddleScreen(huddle: snapshot.data!);
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
