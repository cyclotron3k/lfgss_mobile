import 'package:flutter/material.dart';

import '../../../core/commentable_item.dart';

class CommentThreadSliver extends StatelessWidget {
  final CommentableItem item;
  final int startIndex;
  final int itemCount;
  final bool descending;
  final bool appendRefreshAtEnd;
  final bool refreshDisabled;
  final VoidCallback onRefresh;
  final GlobalKey Function(int index) commentKeyForIndex;

  const CommentThreadSliver({
    super.key,
    required this.item,
    required this.startIndex,
    required this.itemCount,
    this.descending = false,
    this.appendRefreshAtEnd = false,
    this.refreshDisabled = false,
    required this.onRefresh,
    required this.commentKeyForIndex,
  });

  int _indexFor(int localIndex) {
    if (descending) {
      return startIndex - localIndex;
    }
    return startIndex + localIndex;
  }

  Widget _pageDivider(BuildContext context, int index) {
    if (index % 25 == 0) {
      return Row(
        children: [
          const Expanded(child: Divider(endIndent: 8.0)),
          Text(
            'Page ${index ~/ 25 + 1} of ${(item.totalChildren - 1) ~/ 25 + 1}',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).dividerColor,
            ),
          ),
          const Expanded(
            child: Divider(
              indent: 8.0,
            ),
          ),
        ],
      );
    }

    return const Divider();
  }

  @override
  Widget build(BuildContext context) {
    final listItemCount = appendRefreshAtEnd ? itemCount + 1 : itemCount;

    return SliverList.builder(
      itemBuilder: (BuildContext context, int index) {
        if (appendRefreshAtEnd && index == itemCount) {
          return Column(
            children: [
              _pageDivider(context, -1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: refreshDisabled ? null : onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(refreshDisabled ? 'Refreshing...' : 'Refresh'),
                  ),
                ),
              ),
            ],
          );
        }

        final globalIndex = _indexFor(index);
        return Column(
          children: [
            _pageDivider(context, globalIndex),
            KeyedSubtree(
              key: commentKeyForIndex(globalIndex),
              child: item.childTile(globalIndex),
            ),
          ],
        );
      },
      itemCount: listItemCount,
    );
  }
}
