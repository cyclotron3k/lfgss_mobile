import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/comment_tile.dart';

import 'comment_attachments.dart';
import 'flags.dart';
import 'item.dart';
import 'partial_profile.dart';

typedef Json = Map<String, dynamic>;

class Comment implements Item {
  final int id;
  final String itemType; //  "conversation", "profile", etc
  final int itemId;
  final int revisions;
  final int attachments;
  final String markdown;
  final String html;

  // Metadata
  final Flags flags;
  final PartialProfile createdBy;
  // final Profile editedBy;
  final DateTime created;

  CommentAttachments? commentAttachments;

  Item? _context;

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

  @override
  Widget renderAsTile() {
    return CommentTile(comment: this);
  }

  Comment.fromJson({required Json json})
      : id = json["id"],
        itemType = json["itemType"], //  "conversation", "profile", etc
        itemId = json["itemId"],
        revisions = json["revisions"],
        attachments = json["attachments"] ?? 0,
        markdown = json["markdown"],
        html = json["html"],
        createdBy = PartialProfile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json['meta']['editedBy']),
        created = DateTime.parse(json['meta']['created']),
        flags = Flags.fromJson(json: json["meta"]["flags"]);

  bool hasAttachments() {
    return attachments > 0;
  }

  Widget getAttachments({required BuildContext context}) {
    commentAttachments ??=
        CommentAttachments(commentId: id, attachments: attachments);
    return commentAttachments!.build(context);
  }
}
