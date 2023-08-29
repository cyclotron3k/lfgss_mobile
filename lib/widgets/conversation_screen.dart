import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/conversation.dart';
import 'new_comment.dart';

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;
  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
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
      itemBuilder: (BuildContext context, int index) =>
          widget.conversation.childTile(
        widget.conversation.startPage * PAGE_SIZE + index,
      ),
      itemCount: widget.conversation.totalChildren -
          widget.conversation.startPage * PAGE_SIZE,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) =>
          widget.conversation.childTile(
        widget.conversation.startPage * PAGE_SIZE - index - 1,
      ),
      itemCount: widget.conversation.startPage * PAGE_SIZE,
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
                  title: Text(widget.conversation.title),
                ),
                reverseList,
                forwardList,
              ],
            ),
          ),
          if (widget.conversation.flags.open)
            NewComment(
              onPostSuccess: () async {
                await widget.conversation.resetChildren();
                setState(() {});
              },
              itemId: widget.conversation.id,
              itemType: "conversation",
            )
        ],
      ),
    );
  }
}
