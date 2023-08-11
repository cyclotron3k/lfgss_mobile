import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/unknown_item.dart';
import 'dart:developer' as developer;

import '../widgets/future_item_tile.dart';
import 'flags.dart';
import 'microcosm.dart';
// import 'huddle.dart';

import 'item_with_children.dart';
import 'comment.dart';
import '../constants.dart';
import '../api/microcosm_client.dart';
import 'conversation.dart';
// import 'event.dart';
// import 'poll.dart';
import 'item.dart';
import 'update.dart';
// import 'update.dart';

typedef Json = Map<String, dynamic>;

class Updates extends ItemWithChildren {
  final int _totalChildren;
  final Map<int, Item> _children = {};

  Updates.fromJson(Json json) : _totalChildren = json["updates"]["total"] {
    parsePage(json);
  }

  static Future<Updates> root() async {
    var uri = Uri.https(
      HOST,
      "/api/v1/updates",
      {"limit": PAGE_SIZE.toString(), "offset": "0"},
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Updates.fromJson(json);
  }

  @override
  Future<void> getPageOfChildren(int i) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/updates",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * i).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
  }

  @override
  void parsePage(Json json) {
    List<Item> items = json["updates"]["items"]
        .map(
          (item) {
            Item child;
            Item parent;

            switch (item["itemType"]) {
              case "comment":
                {
                  child = Comment.fromJson(json: item["item"]);
                  break;
                }
              case "microcosm":
                {
                  child = Microcosm.fromJson(json: item["item"]);
                  break;
                }
              case "conversation":
                {
                  child = Conversation.fromJson(json: item["item"]);
                  break;
                }
              case "event":
                {
                  // child = Event.fromJson(json: item["item"]);
                  child = UnknownItem(type: item['itemType']);
                  break;
                }
              case "poll":
                {
                  // child = Poll.fromJson(json: item["item"]);
                  child = UnknownItem(type: item['itemType']);
                  break;
                }
              case "huddle":
                {
                  // child = Huddle.fromJson(json: item["item"]);
                  child = UnknownItem(type: item['itemType']);
                  break;
                }
              default:
                {
                  developer.log(
                      "Don't know how to handle itemType of ${item["itemType"]}");
                  return null;
                }
            }

            switch (item["parentItemType"]) {
              case "microcosm":
                {
                  parent = Microcosm.fromJson(json: item["parentItem"]);
                  break;
                }
              case "conversation":
                {
                  parent = Conversation.fromJson(json: item["parentItem"]);
                  break;
                }
              case "event":
                {
                  // parent = Event.fromJson(json: item["parentItem"]);
                  parent = UnknownItem(type: item['parentItemType']);
                  break;
                }
              case "poll":
                {
                  // parent = Poll.fromJson(json: item["parentItem"]);
                  parent = UnknownItem(type: item['parentItemType']);
                  break;
                }
              case "huddle":
                {
                  // parent = Huddle.fromJson(json: item["parentItem"]);
                  parent = UnknownItem(type: item['parentItemType']);
                  break;
                }
              default:
                {
                  developer.log(
                      "Don't know how to handle parentItemType of ${item["parentItemType"]}");
                  return null;
                }
            }

            var flags = Flags.fromJson(json: item["meta"]["flags"]);

            return Update(
              updateType: item["updateType"],
              child: child,
              parent: parent,
              flags: flags,
            );
          },
        )
        .whereType<Item>()
        .toList();

    for (final (index, item) in items.indexed) {
      _children[json["updates"]["offset"] + index] = item;
    }
  }

  Item? _context;

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

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
  Widget renderAsTile() {
    throw UnimplementedError();
  }

  @override
  int get totalChildren => _totalChildren;
}
