import 'package:flutter/material.dart';

import '../../core/item.dart';
import '../../models/comment.dart';
import 'comment_shimmer.dart';

class FutureCommentTile extends StatefulWidget {
  final Future<Comment> comment;
  final int highlight;
  const FutureCommentTile({
    super.key,
    required this.comment,
    this.highlight = 0,
  });

  @override
  State<FutureCommentTile> createState() => _FutureCommentTileState();
}

class _FutureCommentTileState extends State<FutureCommentTile> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: FutureBuilder<Item>(
        future: widget.comment,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Comment comment = snapshot.data! as Comment;
            return comment.renderAsSingleComment(
              highlight: comment.id == widget.highlight,
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 64.0,
              ),
            );
          } else {
            return const CommmentShimmer();
          }
        },
      ),
    );
  }
}
