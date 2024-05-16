import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/authored.dart';
import '../core/item.dart';
import '../core/paginated_item.dart';
import '../models/unknown_item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import '../widgets/tiles/microcosm_tile.dart';
import 'conversation.dart';
import 'event.dart';
import 'flags.dart';
import 'permissions.dart';
import 'profile.dart';

class Microcosm implements PaginatedItem<Item>, Authored {
  @override
  final int startPage;

  @override
  final int id; //  509,
  final int parentId; //  807,
  final int siteId; //  234,
  final String visibility; //  "public",
  final String title; //  "General",
  final String description; //  "For general bike-related chatter.",
  final String _logoUrl; //  "https://lfgss.microcosm.app/api/v1/files/

  // Metadata
  @override
  final Flags flags;
  final Permissions permissions;
  @override
  final Profile createdBy;
  // final Profile editedBy;
  @override
  final DateTime created;

  int _totalChildren;

  final Map<int, Item> _children = {};

  Microcosm.fromJson({
    required Map<String, dynamic> json,
    this.startPage = 0,
  })  : id = json["id"],
        parentId = json["parentId"] ?? 0,
        siteId = json["siteId"],
        visibility = json["visibility"],
        title = HtmlUnescape().convert(json["title"]),
        description = HtmlUnescape().convert(json["description"]),
        _logoUrl = json["logoUrl"],
        createdBy = Profile.fromJson(json: json["meta"]["createdBy"]),
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
  Uri get selfUrl => Uri.https(
        WEB_HOST,
        "/microcosms/$id/",
      );

  @override
  void parsePage(Json json) {
    _totalChildren = json["items"]["total"];

    List<Item> items = json["items"]["items"].map<Item>(
      (item) {
        late Item ret;
        switch (item["itemType"]) {
          case "microcosm":
            {
              ret = Microcosm.fromJson(json: item["item"]);
            }
          case "conversation":
            {
              ret = Conversation.fromJson(json: item["item"]);
            }
          case "event":
            {
              ret = Event.fromJson(json: item["item"]);
            }
          default:
            {
              developer.log("Unknown itemType: ${item["itemType"]}");
              ret = UnknownItem(
                id: item["item"]["id"],
                type: item["itemType"],
              );
            }
        }
        return ret;
      },
    ).toList();

    for (final (index, item) in items.indexed) {
      _children[json["items"]["offset"] + index] = item;
    }
  }

  String get logoUrl {
    return _logoUrl.toString().startsWith('/')
        ? "https://$WEB_HOST$_logoUrl"
        : _logoUrl;
  }

  @override
  int get totalChildren => _totalChildren;

  static Future<Microcosm> root() async {
    Uri uri = Uri.parse(
      "https://$API_HOST/api/v1/microcosms",
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Microcosm.fromJson(json: json);
  }

  static Future<Microcosm> getById(int id) async {
    Uri uri = Uri.parse(
      "https://$API_HOST/api/v1/microcosms/$id",
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Microcosm.fromJson(json: json);
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/microcosms/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    Json json =
        await MicrocosmClient().getJson(uri, ttl: 10, ignoreCache: force);
    parsePage(json);
  }

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
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
  Future<void> resetChildren({bool force = false, int? childId}) async {
    await loadPage(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  Future<Item> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ PAGE_SIZE);

    return _children[i] ?? UnknownItem(id: 0, type: "Unknown");
  }
}
