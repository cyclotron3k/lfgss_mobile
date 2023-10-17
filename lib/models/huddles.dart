import 'package:flutter/material.dart';

import '../constants.dart';
import '../core/item.dart';
import '../core/paginated.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import 'huddle.dart';

class Huddles implements Paginated<Huddle> {
  @override
  final int startPage;
  int _totalChildren;
  final Map<int, Huddle> _children = {};

  Huddles.fromJson({
    required Json json,
    this.startPage = 0,
  }) : _totalChildren = json["huddles"]["total"] {
    parsePage(json);
  }

  static Future<Huddles> root() async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/huddles",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Huddles.fromJson(json: json);
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/huddles",
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
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      return _children[i]!.renderAsTile();
    }
    return FutureItemTile(item: getChild(i));
  }

  @override
  Future<Huddle> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ PAGE_SIZE);

    return _children[i]!;
  }

  @override
  void parsePage(Json json) {
    _totalChildren = json["huddles"]["total"];

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
  Future<void> resetChildren({bool force = false}) async {
    await loadPage(0, force: force);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }

  @override
  int get totalChildren => _totalChildren;
}
