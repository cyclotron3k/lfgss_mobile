import 'package:flutter/material.dart';

import '../../models/search.dart';

class SearchResultsScreen extends StatefulWidget {
  final Search search;
  const SearchResultsScreen({super.key, required this.search});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.search.resetChildren();
        if (context.mounted) setState(() {});
      },
      child: CustomScrollView(
        // cacheExtent: 400.0,
        slivers: <Widget>[
          const SliverAppBar(floating: true, title: Text("Search")),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return widget.search.childTile(index);
              },
              childCount: widget.search.totalChildren,
            ),
          ),
        ],
      ),
    );
  }
}
