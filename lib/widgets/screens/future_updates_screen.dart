import 'package:flutter/material.dart';

import '../../models/updates.dart';
import 'updates_screen.dart';

class FutureUpdatesScreen extends StatefulWidget {
  final Future<Updates> updates;
  final ScrollController? controller;
  final Function onRetry;

  const FutureUpdatesScreen({
    super.key,
    required this.updates,
    required this.onRetry,
    this.controller,
  });

  @override
  State<FutureUpdatesScreen> createState() => _FutureUpdatesScreenState();
}

class _FutureUpdatesScreenState extends State<FutureUpdatesScreen> {
  bool refreshDisabled = false;

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.onRetry();
    } finally {
      setState(() => refreshDisabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Updates>(
      future: widget.updates,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return UpdatesScreen(
            updates: snapshot.data!,
            controller: widget.controller,
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 64.0,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: refreshDisabled ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(refreshDisabled ? 'Retrying...' : 'Retry'),
                ),
              ],
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
