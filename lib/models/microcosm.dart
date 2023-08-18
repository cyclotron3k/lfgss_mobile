import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/unknown_item.dart';

import '../api/microcosm_client.dart';
import '../constants.dart';
import '../widgets/future_item_tile.dart';
import '../widgets/microcosm_tile.dart';
import 'conversation.dart';
import 'flags.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'partial_profile.dart';
import 'permissions.dart';

typedef Json = Map<String, dynamic>;

class Microcosm implements ItemWithChildren {
  Item? _context;
  final int startIndex;

  final int id; //  509,
  final int parentId; //  807,
  final int siteId; //  234,
  final String visibility; //  "public",
  final String title; //  "General",
  final String description; //  "For general bike-related chatter.",
  final String _logoUrl; //  "https://lfgss.microcosm.app/api/v1/files/

  // Metadata
  final Flags flags;
  final Permissions permissions;
  final PartialProfile createdBy;
  // final Profile editedBy;
  final DateTime created;

  final int _totalChildren;

  final Map<int, Item> _children = {};

  // Microcosm({this.startIndex = 0});
  Microcosm.fromJson({required Map<String, dynamic> json, this.startIndex = 0})
      : id = json["id"],
        parentId = json["parentId"] ?? 0,
        siteId = json["siteId"],
        visibility = json["visibility"],
        title = json["title"],
        description = json["description"],
        _logoUrl = json["logoUrl"],
        createdBy = PartialProfile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json['meta']['editedBy']),
        created = DateTime.parse(json['meta']['created']),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        permissions = Permissions.fromJson(
          json: json["meta"]["permissions"] ?? {},
        ),
        _totalChildren = json["items"]?["total"] ?? json["totalItems"] {
    if (json.containsKey("items")) {
      parsePage(json);
    }
  }

  @override
  void parsePage(Json json) {
    List<Item> items = json["items"]["items"].map<Item>(
      (item) {
        switch (item["itemType"]) {
          case "microcosm":
            {
              return Microcosm.fromJson(json: item["item"]);
            }
          case "conversation":
            {
              return Conversation.fromJson(json: item["item"]);
            }
          // case "event":
          //   {
          //     return Event.fromJson(json: item["item"]);
          //   }
          // case "poll":
          //   {
          //     return Poll.fromJson(json: item["item"]);
          //   }
          default:
            {
              // TODO: log
              return UnknownItem(type: item["itemType"]);
            }
        }
      },
    ).toList();

    for (final (index, item) in items.indexed) {
      _children[json["items"]["offset"] + index] = item;
    }
  }

  String get logoUrl {
    // TODO: Pull domain from Site - don't hard-code it
    return _logoUrl.toString().startsWith('/')
        ? "https://lfgss.com$_logoUrl"
        : _logoUrl;
  }

  @override
  int get totalChildren {
    return _totalChildren;
  }

  static Future<Microcosm> root() async {
    Uri uri = Uri.parse(
      "https://$HOST/api/v1/microcosms",
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Microcosm.fromJson(json: json);
  }

  static Future<Microcosm> getById(int id) async {
    Uri uri = Uri.parse(
      "https://$HOST/api/v1/microcosms/$id",
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Microcosm.fromJson(json: json);
  }

  @override
  Future<void> getPageOfChildren(int pageId) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/microcosms/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
  }

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return MicrocosmTile(microcosm: this);
  }

  @override
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      return _children[i]!.renderAsTile();
    }
    return FutureItemTile(item: getChild(i));
  }

  @override
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  Future<Item> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await getPageOfChildren(i ~/ PAGE_SIZE);

    return _children[i] ?? UnknownItem(type: "Unknown");
  }
}
