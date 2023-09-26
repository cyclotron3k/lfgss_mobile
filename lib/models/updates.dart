import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'unknown_item.dart';
import 'update.dart';

class Updates extends ItemWithChildren {
  int _totalChildren;
  final Map<int, Update> _children = {};

  Updates.fromJson(Json json) : _totalChildren = json["updates"]["total"] {
    parsePage(json);
  }

  static Future<Updates> root() async {
    var uri = Uri.https(
      HOST,
      "/api/v1/updates",
      {"limit": PAGE_SIZE.toString(), "offset": "0"},
    );

    Json json = await MicrocosmClient().getJson(uri, ttl: 5);

    return Updates.fromJson(json);
  }

  Future<List<Update>> getNewUpdates() async {
    final sharedPreference =
        await SharedPreferences.getInstance(); //Initialize dependency

    final int lastUpdateId = sharedPreference.getInt("lastUpdateId") ?? 0;

    final Iterable<Update> newUpdates = _children.values.where(
      (update) => update.id > lastUpdateId && update.flags.unread,
    );

    if (newUpdates.isNotEmpty) {
      await sharedPreference.setInt(
        "lastUpdateId",
        newUpdates.first.id,
      );
    }

    return newUpdates.toList();
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

    Json json = await MicrocosmClient().getJson(uri, ttl: 5);
    parsePage(json);
  }

  @override
  void parsePage(Json json) {
    _totalChildren = json["updates"]["total"];
    List<Update> items = json["updates"]["items"]
        .map<Update>((item) => Update.fromJson(item))
        .toList();

    for (final (index, item) in items.indexed) {
      _children[json["updates"]["offset"] + index] = item;
    }
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
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    throw UnimplementedError();
  }

  @override
  int get totalChildren => _totalChildren;
}
