import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/new_comment.dart';

import '../constants.dart';
import '../models/event.dart';

class EventScreen extends StatefulWidget {
  final Event event;
  const EventScreen({super.key, required this.event});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  Widget build(BuildContext context) {
    // final Widget? fab = widget.event.flags.open
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
      itemBuilder: (BuildContext context, int index) => widget.event.childTile(
        widget.event.startPage * PAGE_SIZE + index,
      ),
      itemCount:
          widget.event.totalChildren - widget.event.startPage * PAGE_SIZE,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) => widget.event.childTile(
        widget.event.startPage * PAGE_SIZE - index - 1,
      ),
      itemCount: widget.event.startPage * PAGE_SIZE,
    );

    return Scaffold(
      // floatingActionButton: fab,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              center: forwardListKey,
              slivers: [
                SliverAppBar(
                  // TODO: https://github.com/flutter/flutter/issues/132841
                  floating: true,
                  title: Text(widget.event.title),
                ),
                reverseList,
                forwardList,
              ],
            ),
          ),
          if (widget.event.flags.open)
            NewComment(
              itemId: widget.event.id,
              itemType: "event",
            )
        ],
      ),
    );
  }
}
