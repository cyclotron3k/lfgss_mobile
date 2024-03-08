import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/commentable.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_comment_tile.dart';
import '../widgets/tiles/huddle_tile.dart';
import 'comment.dart';
import 'flags.dart';
import 'permissions.dart';
import 'profile.dart';

class Huddle implements CommentableItem {
  @override
  final int id;
  @override
  final String title;
  final List<Profile> participants;
  @override
  final Flags flags;
  final Permissions permissions;
  @override
  final Profile createdBy;
  @override
  final DateTime created;
  @override
  final int startPage;

  final DateTime? lastActivity;

  int _totalChildren;
  final Map<int, Comment> _children = {};

  final int highlight;

  Huddle.fromJson({
    required Json json,
    this.startPage = 0,
    this.highlight = 0,
  })  : id = json["id"],
        title = HtmlUnescape().convert(json["title"]),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        createdBy = Profile.fromJson(json: json["meta"]["createdBy"]),
        created = DateTime.parse(json['meta']['created']),
        lastActivity = DateTime.tryParse(json["lastCommentCreated"] ?? ""),
        _totalChildren = json["totalComments"] ?? json["comments"]["total"],
        permissions = Permissions.fromJson(json: json['meta']['permissions']),
        participants = json["participants"]
            .map<Profile>((p) => Profile.fromJson(json: p))
            .toList();

  static Future<Huddle> getByCommentId(int commentId) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/comments/$commentId/incontext",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Huddle.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
      highlight: commentId,
    );
  }

  @override
  Uri get selfUrl => Uri.https(
        WEB_HOST,
        "/huddles/$id/newest",
      );

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/huddles/$id",
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

  static Future<Huddle> getById(int id) async {
    // int pageId = await getFirstUnreadPage(id);

    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/huddles/$id/newcomment",
      {
        "limit": PAGE_SIZE.toString(),
        // "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Huddle.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
    );
  }

  @override
  Future<Huddle> getByPageNo(
    int pageNo,
  ) async {
    int offset = (pageNo - 1) * 25;
    // incase we ever increase _our_ page size above 25:
    offset -= offset % PAGE_SIZE;

    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/huddles/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": offset.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Huddle.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
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
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
    return HuddleTile(
      huddle: this,
      overrideUnreadFlag: overrideUnreadFlag,
    );
  }

  @override
  Future<void> resetChildren({bool force = false}) async {
    final int lastPage = _totalChildren ~/ PAGE_SIZE;
    await loadPage(lastPage, force: force);
  }

  @override
  int get totalChildren => _totalChildren;

  @override
  Future<bool> subscribe() async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/watchers",
    );

    final response = await MicrocosmClient().post(uri, {
      "itemType": "huddle",
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
        "itemType": "huddle",
      },
    );

    final response = await MicrocosmClient().delete(uri);
    final bool success = response.statusCode == 200;
    if (success) flags.watched = false;
    return success;
  }

  @override
  bool get canComment => permissions.create;
}
