import 'package:flutter/material.dart';

import '../../models/search.dart';
import 'search_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final Search search;
  final String? title;
  final bool showSummary;
  const SearchResultsScreen({
    super.key,
    required this.search,
    this.title,
    this.showSummary = true,
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
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    maintainState: true,
                    builder: (context) => const SearchScreen(),
                  ),
                ),
                icon: const Icon(Icons.search),
              )
            ],
          ),
          if (widget.showSummary)
            SliverToBoxAdapter(
              child: Material(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 8.0,
                  ),
                  child: Text.rich(TextSpan(text: "Searched for ", children: [
                    TextSpan(
                      text: widget.search.searchParameters.query,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: " and found "),
                    TextSpan(
                      text: "${widget.search.totalChildren}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: " results"),
                  ])),
                ),
              ),
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
