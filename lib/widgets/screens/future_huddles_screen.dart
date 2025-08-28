import 'package:flutter/material.dart';

import '../../models/huddles.dart';
import 'huddles_screen.dart';

class FutureHuddlesScreen extends StatefulWidget {
  final Future<Huddles> huddles;
  final ScrollController? controller;
  final Function onRetry;

  const FutureHuddlesScreen({
    super.key,
    required this.huddles,
    required this.onRetry,
    this.controller,
  });

  @override
  State<FutureHuddlesScreen> createState() => _FutureHuddlesScreenState();
}

class _FutureHuddlesScreenState extends State<FutureHuddlesScreen> {
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
    return FutureBuilder<Huddles>(
      future: widget.huddles,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return HuddlesScreen(
            huddles: snapshot.data!,
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
