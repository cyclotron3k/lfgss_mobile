import 'package:flutter/material.dart';

import '../../models/microcosm.dart';
import 'microcosm_screen.dart';

class FutureMicrocosmScreen extends StatefulWidget {
  final Future<Microcosm> microcosm;
  final ScrollController? controller;
  final Function? onRetry;

  const FutureMicrocosmScreen({
    super.key,
    required this.microcosm,
    this.onRetry,
    this.controller,
  });

  @override
  State<FutureMicrocosmScreen> createState() => _FutureMicrocosmScreenState();
}

class _FutureMicrocosmScreenState extends State<FutureMicrocosmScreen> {
  bool refreshDisabled = false;

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.onRetry!();
    } finally {
      setState(() => refreshDisabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Microcosm>(
      future: widget.microcosm,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MicrocosmScreen(
            microcosm: snapshot.data!,
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
                if (widget.onRetry != null)
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
