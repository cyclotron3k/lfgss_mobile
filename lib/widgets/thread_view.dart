import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../core/commentable_item.dart';
import '../models/comment.dart';

class ThreadView extends StatefulWidget {
  final CommentableItem commentableItem;
  final Comment rootComment;
  const ThreadView({
    super.key,
    required this.commentableItem,
    required this.rootComment,
  });

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  bool infiniteLoop = false;
  final completeFuture = Completer<void>();

  List<Comment> comments = [];
  final spinnerKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    comments.add(widget.rootComment);
    lookup();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      spinnerKey.currentState?.show();
    });
  }

  Future<void> lookup() async {
    final subject = comments.last;
    final nextId = subject.inReplyTo;
    bool done = false;
    if (nextId == null || nextId == 0) {
      completeFuture.complete();
      setState(() {});
      return;
    }

    final cachedComment = widget.commentableItem.getCachedComment(nextId);

    if (cachedComment == null) {
      log("Missing $nextId in cache");
      final nextComment = await subject.getParentComment();
      if (nextComment == null) {
        done = true;
      } else {
        log("Got message $nextId from API");
        comments.add(nextComment);
      }
    } else if (comments.contains(cachedComment)) {
      // Should never happen, but just in case...
      infiniteLoop = true;
      done = true;
    } else {
      log("Got message $nextId from cache");
      comments.add(cachedComment);
    }

    if (done) {
      log("thing is complete");
      completeFuture.complete();
    } else {
      lookup();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        key: spinnerKey,
        notificationPredicate: (_) => false,
        onRefresh: () => completeFuture.future,
        child: ListView.separated(
          reverse: true,
          shrinkWrap: true,
          itemBuilder: (context, index) =>
              comments[index].renderAsSingleComment(
            contextItem: widget.commentableItem,
            hideReply: true,
          ),
          itemCount: comments.length,
          separatorBuilder: (BuildContext context, int index) => const Divider(
            indent: 8.0,
          ),
        ),
      );
}
