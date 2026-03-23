import 'package:flutter/material.dart';
import 'package:lfgss_mobile/core/commentable_item.dart';

import '../../core/item.dart';
import '../../models/comment.dart';
import 'comment_shimmer.dart';

class FutureCommentTile extends StatefulWidget {
  final Future<Comment> comment;
  final CommentableItem contextItem;
  final int highlight;
  const FutureCommentTile({
    super.key,
    required this.comment,
    required this.contextItem,
    this.highlight = 0,
  });

  @override
  State<FutureCommentTile> createState() => _FutureCommentTileState();
}

class _FutureCommentTileState extends State<FutureCommentTile> {
  // Capture the future once in state so that parent rebuilds passing a new
  // Future object (from getChild(i) being called again during a rebuild of
  // CommentThreadSliver) do not cause FutureBuilder to reset to the loading
  // state and re-trigger the network fetch.
  late Future<Comment> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.comment;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: FutureBuilder<Item>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Comment comment = snapshot.data! as Comment;
            return comment.renderAsSingleComment(
              highlight: comment.id == widget.highlight,
              contextItem: widget.contextItem,
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 64.0,
                ),
              ],
            );
          } else {
            return const CommmentShimmer();
          }
        },
      ),
    );
  }
}
