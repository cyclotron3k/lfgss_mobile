import 'package:flutter/material.dart';

import '../../models/search.dart';

class SearchResultsScreen extends StatefulWidget {
  final Search search;
  final String? title;
  const SearchResultsScreen({
    super.key,
    required this.search,
    this.title,
  });

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
          SliverAppBar(
            floating: true,
            title: Text(widget.title ?? "Search"),
          ),
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
