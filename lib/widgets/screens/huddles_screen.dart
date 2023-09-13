import 'package:flutter/material.dart';

import '../../models/huddles.dart';
import '../new_huddle.dart';

class HuddlesScreen extends StatefulWidget {
  final Huddles huddles;
  const HuddlesScreen({
    super.key,
    required this.huddles,
  });

  @override
  State<HuddlesScreen> createState() => _HuddlesScreenState();
}

class _HuddlesScreenState extends State<HuddlesScreen> {
  @override
  Widget build(BuildContext context) {
    final Widget fab = FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: false,
            builder: (context) => const NewHuddle(
              initialParticipants: {},
            ),
          ),
        );
      },
      child: const Icon(Icons.add_comment_rounded),
    );

    return Scaffold(
      floatingActionButton: fab,
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.huddles.resetChildren();
          setState(() {});
        },
        child: CustomScrollView(
          // cacheExtent: 400.0,
          slivers: <Widget>[
            const SliverAppBar(
              floating: true,
              title: Text("Huddles"),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return widget.huddles.childTile(index);
                },
                childCount: widget.huddles.totalChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
