import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../models/updates.dart';

// enum Size { extraSmall, small, medium, large, extraLarge }

class UpdatesScreen extends StatefulWidget {
  final Updates updates;
  const UpdatesScreen({
    super.key,
    required this.updates,
  });

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        developer.log("Refreshing updates screen...");
        widget.updates.resetChildren();
        setState(() {});
      },
      child: CustomScrollView(
        // cacheExtent: 400.0,
        slivers: <Widget>[
          const SliverAppBar(
            floating: true,
            title: Text("Updates"),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return widget.updates.childTile(index);
              },
              childCount: widget.updates.totalChildren,
            ),
          ),
        ],
      ),
    );
  }
}
