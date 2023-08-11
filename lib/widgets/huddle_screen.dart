import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lfgss_mobile/widgets/new_comment.dart';

import '../constants.dart';
import '../models/huddle.dart';

class HuddleScreen extends StatefulWidget {
  final Huddle huddle;
  const HuddleScreen({super.key, required this.huddle});

  @override
  State<HuddleScreen> createState() => _HuddleScreenState();
}

class _HuddleScreenState extends State<HuddleScreen> {
  @override
  Widget build(BuildContext context) {
    // final Widget? fab = widget.conversation.flags.open
    //     ? FloatingActionButton(
    //         onPressed: () {
    //           // Add your onPressed code here!
    //         },
    //         // backgroundColor: Colors.green,
    //         child: const Icon(Icons.add_comment),
    //       )
    //     : null;

    Key forwardListKey = UniqueKey();
    Widget forwardList = SliverList.builder(
      key: forwardListKey,
      itemBuilder: (BuildContext context, int index) => widget.huddle.childTile(
        widget.huddle.startPage * PAGE_SIZE + index,
      ),
      itemCount:
          widget.huddle.totalChildren - widget.huddle.startPage * PAGE_SIZE,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) => widget.huddle.childTile(
        widget.huddle.startPage * PAGE_SIZE - index - 1,
      ),
      itemCount: widget.huddle.startPage * PAGE_SIZE,
    );

    return Scaffold(
      // floatingActionButton: fab,
      body: Column(
        children: [
          Expanded(
            child: Scrollable(
              viewportBuilder: (BuildContext context, ViewportOffset offset) {
                return Viewport(
                  offset: offset,
                  center: forwardListKey,
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      title: Text(widget.huddle.title),
                    ),
                    reverseList,
                    forwardList,
                  ],
                );
              },
            ),
          ),
          if (widget.huddle.flags.open)
            NewComment(
              itemId: widget.huddle.id,
              itemType: "conversation",
            )
        ],
      ),
    );
  }
}
