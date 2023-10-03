import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../models/huddle.dart';
import '../../models/reply_notifier.dart';
import '../../services/microcosm_client.dart';
import '../new_comment.dart';

class HuddleScreen extends StatefulWidget {
  final Huddle huddle;
  const HuddleScreen({super.key, required this.huddle});

  @override
  State<HuddleScreen> createState() => _HuddleScreenState();
}

class _HuddleScreenState extends State<HuddleScreen> {
  @override
  Widget build(BuildContext context) {
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
      body: ChangeNotifierProvider<ReplyNotifier>(
        create: (BuildContext context) => ReplyNotifier(),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await widget.huddle.resetChildren();
                  setState(() {});
                },
                child: Scrollable(
                  viewportBuilder:
                      (BuildContext context, ViewportOffset offset) {
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
            ),
            if (widget.huddle.permissions.create && MicrocosmClient().loggedIn)
              NewComment(
                itemId: widget.huddle.id,
                itemType: CommentableType.huddle,
                onPostSuccess: () async {
                  await widget.huddle.resetChildren();
                  setState(() {});
                },
              )
          ],
        ),
      ),
    );
  }
}
