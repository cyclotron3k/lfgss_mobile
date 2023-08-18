import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/partial_profile.dart';
import 'package:lfgss_mobile/models/unknown_item.dart';

import '../api/microcosm_client.dart';
import '../constants.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/future_item_tile.dart';
import 'comment.dart';
import 'flags.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'permissions.dart';

typedef Json = Map<String, dynamic>;

class Conversation implements ItemWithChildren {
  final int startPage;

  final int id;
  final String title;
  final int microcosmId;

  // Metadata
  final Flags flags;
  final Permissions permissions;
  final PartialProfile createdBy;
  // final Profile editedBy;
  final DateTime created;

  final int _totalChildren;
  final Map<int, Item> _children = {};

  Conversation.fromJson(
      {required Map<String, dynamic> json, this.startPage = 0})
      : id = json["id"],
        title = json["title"],
        microcosmId = json["microcosmId"],
        createdBy = PartialProfile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json['meta']['editedBy']),
        created = DateTime.parse(json['meta']['created']),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        permissions = Permissions.fromJson(
          json: json["meta"]["permissions"] ?? {},
        ),
        _totalChildren = json["comments"]?["total"] ?? json["totalComments"] {
    if (json.containsKey("comments")) {
      parsePage(json);
    }
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
  int get totalChildren => _totalChildren;

  static Future<Conversation> getById(int id) async {
    Uri uri = Uri.https(
      HOST,
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

  @override
  Future<void> getPageOfChildren(int i) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/conversations/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * i).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
  }

  Item? _context;

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

  @override
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return ConversationTile(
      conversation: this,
      overrideUnreadFlag: overrideUnreadFlag,
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
    // TODO: why are children not being set?
    return _children[i] ?? UnknownItem(type: "Unknown");
  }
}
