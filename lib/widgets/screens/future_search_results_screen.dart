import 'package:flutter/material.dart';

import '../../models/search.dart';
import 'search_results_screen.dart';

class FutureSearchResultsScreen extends StatefulWidget {
  final Future<Search> search;
  final ScrollController? controller;
  final String? title;
  final bool showSummary;
  final bool autoUpdate;
  final Function? onRetry;

  const FutureSearchResultsScreen({
    super.key,
    required this.search,
    this.controller,
    this.title,
    this.showSummary = true,
    this.autoUpdate = false,
    this.onRetry,
  });

  @override
  State<FutureSearchResultsScreen> createState() =>
      _FutureSearchResultsScreenState();
}

class _FutureSearchResultsScreenState extends State<FutureSearchResultsScreen> {
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
    return FutureBuilder<Search>(
      future: widget.search,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SearchResultsScreen(
            search: snapshot.data!,
            title: widget.title,
            showSummary: widget.showSummary,
            autoUpdate: widget.autoUpdate,
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
