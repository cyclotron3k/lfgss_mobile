import 'package:flutter/material.dart';

import '../models/search.dart';

class SearchResultsScreen extends StatefulWidget {
  final Search search;
  const SearchResultsScreen({super.key, required this.search});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: null,
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO
          return Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Not implemented yet'),
                  duration: Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
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
      ),
    );
  }
}
