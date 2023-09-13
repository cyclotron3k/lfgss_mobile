import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:lfgss_mobile/models/permissions.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import '../widgets/tiles/huddle_tile.dart';
import 'comment.dart';
import 'flags.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'partial_profile.dart';
import 'unknown_item.dart';

class Huddle extends ItemWithChildren {
  final int id;
  final String title;
  final List<PartialProfile> participants;
  final Flags flags;
  final Permissions permissions;
  final PartialProfile createdBy;
  final DateTime created;
  final int startPage;

  final int _totalChildren;
  final Map<int, Item> _children = {};

  Huddle.fromJson({required Json json, this.startPage = 0})
      : id = json["id"],
        title = HtmlUnescape().convert(json["title"]),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        createdBy = PartialProfile.fromJson(json: json["meta"]["createdBy"]),
        created = DateTime.parse(json['meta']['created']),
        _totalChildren = json["totalComments"] ?? json["comments"]["total"],
        permissions = Permissions.fromJson(json: json['meta']['permissions']),
        participants = json["participants"]
            .map<PartialProfile>((p) => PartialProfile.fromJson(json: p))
            .toList();

  @override
  Future<void> getPageOfChildren(int i) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/huddles/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * i).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
  }

  static Future<Huddle> getById(int id) async {
    // int pageId = await getFirstUnreadPage(id);

    Uri uri = Uri.https(
      HOST,
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
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      return _children[i]!.renderAsTile();
    }
    return FutureItemTile(item: getChild(i));
  }

  @override
  Future<Item> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await getPageOfChildren(i ~/ PAGE_SIZE);

    return _children[i] ?? UnknownItem(type: "Unknown");
  }

  @override
  void parsePage(Json json) {
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
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return HuddleTile(huddle: this);
  }

  @override
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  int get totalChildren => _totalChildren;
}
