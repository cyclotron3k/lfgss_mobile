import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/authored.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/comment_tile.dart';
import 'comment_attachments.dart';
import 'flags.dart';
import 'links.dart' hide Json;
import 'profile.dart';

class Comment implements Item, Authored {
  @override
  final int id;
  final String itemType; //  "conversation", "profile", etc
  final int itemId;
  final int revisions;
  final int attachments;
  final int? inReplyTo;
  final String markdown;
  final String html;
  final Links links;

  @override
  DateTime created;

  @override
  Profile createdBy;

  @override
  Flags flags;

  Comment? _replyTo;
  List<Comment>? _replies;

  CommentAttachments? commentAttachments;

  @override
  Uri get selfUrl => Uri.https(WEB_HOST, "/comments/$id");

  Future<Comment> getReplyTo() async {
    if (_replyTo != null) return _replyTo!;

    if (inReplyTo != null) {
      Uri uri = Uri.https(
        API_HOST,
        "/api/v1/comments/$id",
      );

      Json json = await MicrocosmClient().getJson(uri);

      _replyTo = Comment.fromJson(json: json["meta"]["inReplyTo"]);
      _replies = <Comment>[];
      for (var reply in json["meta"]["replies"] as List<Json>) {
        _replies!.add(Comment.fromJson(json: reply));
      }
    }
    return _replyTo!;
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag, bool highlight = false}) {
    return CommentTile(comment: this, highlight: highlight);
  }

  Comment.fromJson({required Json json})
      : id = json["id"],
        itemType = json["itemType"], //  "conversation", "profile", etc
        itemId = json["itemId"],
        revisions = json["revisions"],
        attachments = json["attachments"] ?? 0,
        markdown = HtmlUnescape().convert(json["markdown"]),
        inReplyTo = json["inReplyTo"],
        html = json["html"],
        createdBy = Profile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json['meta']['editedBy']),
        created = DateTime.parse(json['meta']['created']),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        links = Links.fromJson(json: json["meta"]["links"]);

  bool hasAttachments() {
    return attachments > 0;
  }

  Widget getAttachments({required BuildContext context}) {
    commentAttachments ??=
        CommentAttachments(commentId: id, attachments: attachments);
    return commentAttachments!.build(context);
  }
}
