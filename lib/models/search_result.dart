import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../core/commentable_item.dart';
import '../core/item.dart';
import '../widgets/tiles/comment_tile.dart';
import '../widgets/tiles/profile_comment_tile.dart';
import 'flags.dart';
import 'item_parser.dart' hide Json;
import 'profile.dart';

class SearchResult implements Item {
  final Item child;
  final Item? parent;

  final bool unread; // true,
  // final double rank; // 0.5,
  // final DateTime lastModified; // "2023-08-26T22:32:14.81666Z",
  final String highlight; // ""

  SearchResult({
    required this.child,
    this.parent,
    required this.unread,
    // required this.rank,
    required this.highlight,
  });

  SearchResult.fromJson(Json json)
      : child = ItemParser.parseItemJson(
          json["itemType"],
          json["item"],
        ),
        parent = json["parentItemType"] == null
            ? null
            : ItemParser.parseItemJson(
                json["parentItemType"],
                json["parentItem"],
              ),
        unread = json["unread"],
        // rank = json["rank"],
        highlight = json["highlight"];

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
    if (parent is CommentableItem && child is Comment) {
      return CommentTile(
        comment: child as Comment,
        contextItem: parent as CommentableItem,
        highlight: highlight,
        overrideUnreadFlag: overrideUnreadFlag ?? unread,
      );
    } else if (parent is Profile && child is Comment) {
      return ProfileCommentTile(
        comment: child as Comment,
        profile: parent as Profile,
        highlight: highlight,
        overrideUnreadFlag: overrideUnreadFlag ?? unread,
      );
    } else {
      return child.renderAsTile(
        overrideUnreadFlag: overrideUnreadFlag ?? unread,
      );
    }
  }

  @override
  int get id => child.id;

  @override
  Uri get selfUrl => throw UnimplementedError();

  @override
  Flags get flags => throw UnimplementedError();
}
