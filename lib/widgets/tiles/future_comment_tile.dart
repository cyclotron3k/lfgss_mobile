import 'package:flutter/material.dart';
import 'package:lfgss_mobile/core/commentable_item.dart';

import '../../core/item.dart';
import '../../models/comment.dart';
import 'comment_shimmer.dart';

class FutureCommentTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: FutureBuilder<Item>(
        future: comment,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Comment comment = snapshot.data! as Comment;
            return comment.renderAsSingleComment(
              highlight: comment.id == highlight,
              contextItem: contextItem,
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 64.0,
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
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
