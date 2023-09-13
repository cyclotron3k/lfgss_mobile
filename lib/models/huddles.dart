import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import 'huddle.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'unknown_item.dart';

class Huddles extends ItemWithChildren {
  final int _totalChildren;
  final Map<int, Item> _children = {};

  Huddles.fromJson({required Json json})
      : _totalChildren = json["huddles"]["total"] {
    parsePage(json);
  }

  static Future<Huddles> root() async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/huddles",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Huddles.fromJson(json: json);
  }

  @override
  Future<void> getPageOfChildren(int i) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/huddles",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * i).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
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
    List<Huddle> comments = json["huddles"]["items"]
        .map<Huddle>(
          (comment) => Huddle.fromJson(json: comment),
        )
        .toList();

    for (final (index, comment) in comments.indexed) {
      _children[json["huddles"]["offset"] + index] = comment;
    }
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    // TODO: implement renderAsTile
    return const Placeholder();
  }

  @override
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  int get totalChildren => _totalChildren;
}
