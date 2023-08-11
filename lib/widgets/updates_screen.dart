import 'package:flutter/material.dart';
import '../models/updates.dart';

enum Sizes { extraSmall, small, medium, large, extraLarge }

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({
    super.key,
    required this.updates,
  });

  final Updates updates;

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  // Set<Sizes> selection = <Sizes>{Sizes.large, Sizes.extraLarge};

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
