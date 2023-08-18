import 'package:flutter/material.dart';

import '../models/updates.dart';
import 'updates_screen.dart';

class FutureUpdatesScreen extends StatefulWidget {
  final Future<Updates> updates;
  const FutureUpdatesScreen({super.key, required this.updates});

  @override
  State<FutureUpdatesScreen> createState() => _FutureUpdatesScreenState();
}

class _FutureUpdatesScreenState extends State<FutureUpdatesScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Updates>(
      future: widget.updates,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return UpdatesScreen(updates: snapshot.data!);
        } else if (snapshot.hasError) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
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
