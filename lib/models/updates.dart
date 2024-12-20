import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import '../core/item.dart';
import '../core/paginated.dart';
import 'unknown_item.dart';
import 'update.dart';

class Updates extends Paginated<Item> {
  @override
  final int startPage;
  int _totalChildren;
  final Map<int, Update> _children = {};

  Updates.fromJson({
    required Json json,
    this.startPage = 0,
  }) : _totalChildren = json["updates"]["total"] {
    parsePage(json);
  }

  static Future<Updates> root({int pageSize = PAGE_SIZE}) async {
    var uri = Uri.https(
      API_HOST,
      "/api/v1/updates",
      {"limit": pageSize.toString(), "offset": "0"},
    );

    Json json = await MicrocosmClient().getJson(uri, ttl: 5);

    return Updates.fromJson(json: json);
  }

  Uri get selfUrl => Uri.https(
        WEB_HOST,
        "/updates/",
      );

  Future<List<Update>> getNewUpdates() async {
    final sharedPreference = await SharedPreferences.getInstance();

    final int? spUpdateId = sharedPreference.getInt("lastUpdateId");

    // Only show updates newer than this:
    final int lastUpdateId = spUpdateId ?? _highTide ?? 0;

    final Iterable<Update> newUpdates = _children.values.where(
      (update) => update.id > lastUpdateId && update.flags.unread,
    );

    if (newUpdates.isNotEmpty || spUpdateId != lastUpdateId) {
      int id = newUpdates.isNotEmpty ? newUpdates.first.id : lastUpdateId;
      await sharedPreference.setInt(
        "lastUpdateId",
        id,
      );
    }

    return newUpdates.toList();
  }

  int? get _highTide {
    Update? lastUpdate = maxBy<Update, int>(_children.values, (c) => c.id);
    if (lastUpdate != null) {
      return lastUpdate.id;
    }
    return null;
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/updates",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(
      uri,
      ttl: 5,
      ignoreCache: force,
    );
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
    await loadPage(i ~/ PAGE_SIZE);

    return _children[i] ?? UnknownItem(id: 0, type: "Unknown");
  }

  @override
  Future<void> resetChildren({bool force = false, int? childId}) async {
    await loadPage(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  int get totalChildren => _totalChildren;
}
