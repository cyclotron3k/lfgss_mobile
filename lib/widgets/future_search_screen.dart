import 'package:flutter/material.dart';

import 'search_results_screen.dart';
import '../models/search.dart';

class FutureSearchScreen extends StatefulWidget {
  final Future<Search> search;
  const FutureSearchScreen({super.key, required this.search});

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
          return SearchResultsScreen(search: snapshot.data!);
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
