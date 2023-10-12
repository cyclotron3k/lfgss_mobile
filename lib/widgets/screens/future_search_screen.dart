import 'package:flutter/material.dart';

import '../../models/search.dart';
import 'search_results_screen.dart';

class FutureSearchScreen extends StatefulWidget {
  final Future<Search> search;
  final String? title;
  const FutureSearchScreen({super.key, required this.search, this.title});

  @override
  State<FutureSearchScreen> createState() => _FutureSearchScreenState();
}

class _FutureSearchScreenState extends State<FutureSearchScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Search>(
      future: widget.search,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SearchResultsScreen(
            search: snapshot.data!,
            title: widget.title,
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
