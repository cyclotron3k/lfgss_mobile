import 'package:flutter/material.dart';

import '../models/microcosm.dart';
import 'microcosm_screen.dart';

class FutureMicrocosmScreen extends StatefulWidget {
  final Future<Microcosm> microcosm;
  const FutureMicrocosmScreen({super.key, required this.microcosm});

  @override
  State<FutureMicrocosmScreen> createState() => _FutureMicrocosmScreenState();
}

class _FutureMicrocosmScreenState extends State<FutureMicrocosmScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Microcosm>(
      future: widget.microcosm,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MicrocosmScreen(microcosm: snapshot.data!);
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
