import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/item_with_children.dart';

import '../api/microcosm_client.dart';
import '../constants.dart';
// import '../services/constants.dart';
// import '../services/microcosm_api.dart';
// import '../widgets/item_loading.dart';
import '../widgets/future_item_tile.dart';
import 'comment.dart';
import 'conversation.dart';

import 'microcosm.dart';

import 'partial_profile.dart';
import 'profile.dart';
import 'item.dart';
import 'search_parameters.dart';
import 'dart:developer' as developer;

import 'search_result.dart';
import 'unknown_item.dart';

typedef Json = Map<String, dynamic>;

class Search extends ItemWithChildren {
  SearchParameters searchParameters;

  final int _totalChildren;
  final Map<int, Item> _children = {};

  // Search({
  //   required this.searchParameters,
  //   required this.totalPages,
  //   required this.firstPage,
  // });

  Search.fromJson({required this.searchParameters, required Json json})
      : _totalChildren = json["results"]["total"] {
    parsePage(json);
  }

  @override
  void parsePage(Json json) {
    List<Item> items = json["results"]["items"]
        .map(
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
              // case "huddle":
              //   {
              //     return Poll.fromJson(json: item["item"]);
              //   }
              case "profile":
                {
                  return PartialProfile.fromJson(json: item["item"]);
                }
              default:
                {
                  // TODO: log
                  return UnknownItem(type: item["itemType"]);
                }
            }
          },
        )
        .whereType<Item>()
        .toList();

    for (final (index, item) in items.indexed) {
      _children[json["results"]["offset"] + index] = item;
    }
  }

  static Future<Search> search({
    required SearchParameters searchParameters,
  }) async {
    var parameters = searchParameters.asQueryParameters;
    parameters["limit"] = PAGE_SIZE.toString();
    parameters["offset"] = "0";

    Uri uri = Uri.https(
      HOST,
      "/api/v1/search",
      parameters,
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Search.fromJson(
      searchParameters: searchParameters,
      json: json,
    );
  }

  @override
  int get totalChildren {
    return _totalChildren;
  }

  @override
  Future<void> getPageOfChildren(int i) async {
    var parameters = searchParameters.asQueryParameters;
    parameters["limit"] = PAGE_SIZE.toString();
    parameters["offset"] = (PAGE_SIZE * i).toString();

    Uri uri = Uri.https(
      HOST,
      "/api/v1/search",
      parameters,
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
  }

  static List<SearchResult> parseChildren(List<dynamic> items) {
    List<SearchResult> results = items
        .map(
          (item) {
            Item child;
            Item? parent;

            switch (item["itemType"]) {
              case "comment":
                {
                  child = Comment.fromJson(json: item["item"]);
                  // (child as Comment).unread = item["unread"];
                  break;
                }
              case "microcosm":
                {
                  child = Microcosm.fromJson(json: item["item"]);
                  // (child as Microcosm).flags.unread = item["unread"];
                  break;
                }
              case "conversation":
                {
                  child = Conversation.fromJson(json: item["item"]);
                  // (child as Conversation).flags.unread = item["unread"];
                  break;
                }
              // case "event":
              //   {
              //     child = Event.fromJson(json: item["item"]);
              //     (child as Event).unread = item["unread"];
              //     break;
              //   }
              // case "poll":
              //   {
              //     child = Poll.fromJson(json: item["item"]);
              //     (child as Poll).unread = item["unread"];
              //     break;
              //   }
              // case "huddle":
              //   {
              //     child = Huddle.fromJson(json: item["item"]);
              //     (child as Huddle).unread = item["unread"];
              //     break;
              //   }
              case "profile":
                {
                  child = Profile.fromJson(json: item["item"]);
                  // (child as Profile).unread = item["unread"];
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
              case null:
                {
                  // Do nothing
                  break;
                }
              case "microcosm":
                {
                  parent = Microcosm.fromJson(json: item["parentItem"]);
                  // (parent as Microcosm).unread =
                  // item["meta"]["flags"]["unread"];
                  break;
                }
              case "conversation":
                {
                  parent = Conversation.fromJson(json: item["parentItem"]);
                  // (parent as Conversation).unread =
                  // item["meta"]["flags"]["unread"];
                  break;
                }
              // case "event":
              //   {
              //     parent = Event.fromJson(json: item["parentItem"]);
              //     (parent as Event).unread = item["meta"]["flags"]["unread"];
              //     break;
              //   }
              // case "poll":
              //   {
              //     parent = Poll.fromJson(json: item["parentItem"]);
              //     (parent as Poll).unread = item["meta"]["flags"]["unread"];
              //     break;
              //   }
              // case "huddle":
              //   {
              //     parent = Huddle.fromJson(json: item["parentItem"]);
              //     (parent as Huddle).unread =
              //         item["meta"]?["flags"]?["unread"] ?? false;
              //     break;
              //   }
              default:
                {
                  developer.log(
                      "Don't know how to handle parentItemType of ${item["parentItemType"]}");
                  return null;
                }
            }

            return SearchResult(
              child: child,
              parent: parent,
            );
          },
        )
        .whereType<SearchResult>()
        .toList();

    return results;
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

  Item? _context;

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

  @override
  Widget renderAsTile() {
    // TODO: implement renderAsTile
    return const Placeholder();
  }
}
