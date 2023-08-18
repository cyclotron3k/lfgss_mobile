import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/updates.dart';

// enum Sizes { extraSmall, small, medium, large, extraLarge }

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
          // SliverToBoxAdapter(
          //   child: SegmentedButton<Sizes>(
          //     segments: const <ButtonSegment<Sizes>>[
          //       ButtonSegment<Sizes>(
          //         value: Sizes.extraSmall,
          //         label: Text('Updates'),
          //         icon: Icon(Icons.chat),
          //       ),
          //       ButtonSegment<Sizes>(
          //         value: Sizes.small,
          //         label: Text('Mentions'),
          //         icon: Icon(Icons.alternate_email),
          //       ),
          //       ButtonSegment<Sizes>(
          //         value: Sizes.medium,
          //         label: Text('Replies'),
          //         icon: Icon(Icons.reply),
          //       ),
          //       ButtonSegment<Sizes>(
          //         value: Sizes.large,
          //         label: Text('Chats'),
          //         icon: Icon(Icons.email),
          //       ),
          //     ],
          //     selected: selection,
          //     onSelectionChanged: (Set<Sizes> newSelection) {
          //       setState(() {
          //         selection = newSelection;
          //       });
          //     },
          //     multiSelectionEnabled: true,
          //   ),
          // ),
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
