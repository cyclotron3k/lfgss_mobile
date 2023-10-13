import 'package:flutter/material.dart';

import '../../models/search.dart';
import 'search_results_screen.dart';

class FutureSearchResultsScreen extends StatefulWidget {
  final Future<Search> search;
  final String? title;
  final bool showSummary;
  const FutureSearchResultsScreen({
    super.key,
    required this.search,
    this.title,
    this.showSummary = true,
  });

  @override
  State<FutureSearchResultsScreen> createState() =>
      _FutureSearchResultsScreenState();
}

class _FutureSearchResultsScreenState extends State<FutureSearchResultsScreen> {
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
          );
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
