import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/conversation.dart';
import '../../services/microcosm_client.dart';
import '../new_comment.dart';

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;
  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  @override
  Widget build(BuildContext context) {
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
          if (widget.conversation.flags.open && MicrocosmClient().loggedIn)
            NewComment(
              itemId: widget.conversation.id,
              itemType: CommentableType.conversation,
              onPostSuccess: () async {
                await widget.conversation.resetChildren();
                setState(() {});
              },
            )
        ],
      ),
    );
  }
}
