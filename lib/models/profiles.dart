import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'partial_profile.dart';
import 'unknown_item.dart';

class Profiles extends ItemWithChildren {
  String query;

  int _totalChildren;
  final Map<int, Item> _children = {};

  Profiles.fromJson({required this.query, required Json json})
      : _totalChildren = json["profiles"]["total"] {
    parsePage(json);
  }

  int get _pageSize {
    return 25; // Watch out for line 31
  }

  static Future<Profiles> search({
    required String query,
  }) async {
    Map<String, String> parameters = {
      "q": query,
      "top": "true",
      "limit": "25",
      "offset": "0",
    };

    Uri uri = Uri.https(
      HOST,
      "/api/v1/profiles",
      parameters,
    );

    Json json = await MicrocosmClient().getJson(uri, ttl: 3600);

    return Profiles.fromJson(
      query: query,
      json: json,
    );
  }

  @override
  int get totalChildren {
    return _totalChildren;
  }

  @override
  Future<void> getPageOfChildren(int i) async {
    Map<String, String> parameters = {
      "q": query,
      "top": "true",
      "limit": _pageSize.toString(),
      "offset": (_pageSize * i).toString(),
    };

    Uri uri = Uri.https(
      HOST,
      "/api/v1/profiles",
      parameters,
    );

    Json json = await MicrocosmClient().getJson(uri, ttl: 3600);
    parsePage(json);
  }

  @override
  void parsePage(Json json) {
    _totalChildren = json["profiles"]["total"];

    List<PartialProfile> results = json["profiles"]["items"]
        .map<PartialProfile>((item) => PartialProfile.fromJson(json: item))
        .toList();

    for (final (index, item) in results.indexed) {
      _children[json["profiles"]["offset"] + index] = item;
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
    await getPageOfChildren(i ~/ _pageSize);
    return _children[i] ?? UnknownItem(type: "Unknown");
  }

  @override
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= _pageSize);
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    // TODO: implement renderAsTile
    return const Placeholder();
  }
}
