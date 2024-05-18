import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/authored.dart';
import '../core/commentable_item.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/single_comment.dart';
import 'comment_attachments.dart';
import 'conversation.dart';
import 'event.dart';
import 'flags.dart';
import 'huddle.dart';
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

  Comment? _parentComment;
  List<Comment>? _replies;

  CommentAttachments? commentAttachments;

  @override
  Uri get selfUrl => Uri.https(WEB_HOST, "/comments/$id");

  Future<Comment?> getParentComment() async {
    if (inReplyTo == null) return null;
    if (_parentComment != null) return _parentComment;

    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/comments/$inReplyTo",
    );
    Json json = await MicrocosmClient().getJson(uri);

    _parentComment = Comment.fromJson(json: json);

    return _parentComment;
  }

  Future<List<Comment>> getReplies() async {
    if (_replies != null) return _replies!;

    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/comments/$id",
    );
    Json json = await MicrocosmClient().getJson(uri);

    _parentComment = Comment.fromJson(json: json["meta"]["inReplyTo"]);
    _replies = <Comment>[];
    for (var reply in json["meta"]["replies"] as List<Json>) {
      _replies!.add(Comment.fromJson(json: reply));
    }

    return _replies!;
  }

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
    bool highlight = false,
  }) {
    return const Placeholder(); // CommentTile(comment: this);
  }

  Widget renderAsSingleComment({
    bool? overrideUnreadFlag,
    bool highlight = false,
  }) {
    return SingleComment(comment: this, highlight: highlight);
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
        links = Links.fromJson(json: json["meta"]["links"]) {
    if (json["meta"]?["replies"] != null) {
      _replies = <Comment>[];
      for (var reply in json["meta"]["replies"] as List<Json>) {
        _replies!.add(Comment.fromJson(json: reply));
      }
    }
    if (json["meta"]?["inReplyTo"] != null) {
      _parentComment = Comment.fromJson(json: json["meta"]["inReplyTo"]);
    }
  }

  bool hasAttachments() {
    return attachments > 0;
  }

  Future<CommentableItem> get container {
    if (itemType == 'conversation') {
      return Conversation.getByCommentId(id);
    } else if (itemType == 'event') {
      return Event.getByCommentId(id);
    } else if (itemType == 'huddle') {
      return Huddle.getByCommentId(id);
    } else {
      throw "Unrecognised itemType: $itemType";
    }
  }

  Widget getAttachments({required BuildContext context}) {
    commentAttachments ??=
        CommentAttachments(commentId: id, attachments: attachments);
    return commentAttachments!.build(context);
  }
}
