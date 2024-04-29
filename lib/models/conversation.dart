import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/commentable.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/conversation_tile.dart';
import '../widgets/tiles/future_comment_tile.dart';
import 'comment.dart';
import 'flags.dart';
import 'permissions.dart';
import 'profile.dart';

class Conversation implements CommentableItem {
  @override
  final int startPage;

  @override
  final int id;

  @override
  final String title;
  final int microcosmId;

  // Metadata
  final Permissions permissions;

  @override
  DateTime created;

  @override
  Profile createdBy;

  @override
  Flags flags;
  final DateTime? lastActivity;

  int _totalChildren;
  final Map<int, Comment> _children = {};

  final int highlight;

  Conversation.fromJson({
    required Json json,
    this.startPage = 0,
    this.highlight = 0,
  })  : id = json["id"],
        title = HtmlUnescape().convert(json["title"]),
        microcosmId = json["microcosmId"],
        createdBy = Profile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json['meta']['editedBy']),
        created = DateTime.parse(json['meta']['created']),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        permissions = Permissions.fromJson(
          json: json["meta"]["permissions"] ?? {},
        ),
        lastActivity = DateTime.tryParse(json["lastComment"]?["created"] ?? ""),
        _totalChildren = json["comments"]?["total"] ?? json["totalComments"] {
    if (json.containsKey("comments")) {
      parsePage(json);
    }
  }

  @override
  Future<bool> subscribe() async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/watchers",
    );

    final response = await MicrocosmClient().post(uri, {
      "itemType": "conversation",
      "itemId": id,
      "updateTypeId": 1,
    });
    final bool success = response.statusCode == 200;
    if (success) flags.watched = true;
    return success;
  }

  @override
  Future<bool> unsubscribe() async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/watchers/delete",
      {
        "updateTypeId": "1",
        "itemId": id.toString(),
        "itemType": "conversation",
      },
    );

    final response = await MicrocosmClient().delete(uri);
    final bool success = response.statusCode == 200;
    if (success) flags.watched = false;
    return success;
  }

  @override
  Uri get selfUrl => Uri.https(
        WEB_HOST,
        "/conversations/$id/newest",
      );

  @override
  void parsePage(Json json) {
    _totalChildren = json["comments"]["total"];

    List<Comment> comments = json["comments"]["items"]
        .map<Comment>(
          (comment) => Comment.fromJson(json: comment),
        )
        .toList();

    for (final (index, comment) in comments.indexed) {
      _children[json["comments"]["offset"] + index] = comment;
    }
  }

  @override
  int get totalChildren => _totalChildren;

  static Future<Conversation> getById(int id) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/conversations/$id/newcomment",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Conversation.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
    );
  }

  static Future<Conversation> getByCommentId(int commentId) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/comments/$commentId/incontext",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Conversation.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
      highlight: commentId,
    );
  }

  @override
  Future<Conversation> getItemByCommentId(int commentId) =>
      Conversation.getByCommentId(commentId);

  @override
  Future<Conversation> getByPageNo(
    int pageNo,
  ) async {
    int offset = (pageNo - 1) * 25;
    // incase we ever increase _our_ page size above 25:
    offset -= offset % PAGE_SIZE;

    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/conversations/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": offset.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Conversation.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
    );
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/conversations/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    final bool lastPage = pageId == totalChildren ~/ PAGE_SIZE;
    final int ttl = lastPage ? 5 : 3600;

    Json json = await MicrocosmClient().getJson(
      uri,
      ttl: ttl,
      ignoreCache: force,
    );
    parsePage(json);
  }

  @override
  Future<void> resetChildren({bool force = false, int? childId}) async {
    final int pageId;

    int index = -1;
    if (childId != null) {
      index = _children.keys.firstWhere(
        (k) => _children[k]!.id == childId,
        orElse: () => -1,
      );
    }

    if (index >= 0) {
      pageId = index ~/ PAGE_SIZE;
    } else {
      pageId = _totalChildren ~/ PAGE_SIZE;
    }

    await loadPage(pageId, force: true);
  }

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
    return ConversationTile(
      conversation: this,
      overrideUnreadFlag: overrideUnreadFlag,
      isReply: isReply,
      mentioned: mentioned,
    );
  }

  @override
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      var comment = _children[i]!;
      return comment.renderAsSingleComment(highlight: highlight == comment.id);
    }
    return FutureCommentTile(
      comment: getChild(i),
      highlight: highlight,
    );
  }

  @override
  Future<Comment> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ PAGE_SIZE);
    return _children[i]!;
  }

  @override
  bool get canComment => flags.open && permissions.create;
}
