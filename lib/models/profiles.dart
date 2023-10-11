import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import '../core/item.dart';
import '../core/paginated.dart';
import 'profile.dart';

class Profiles implements Paginated<Profile> {
  @override
  final int startPage;
  String query;

  int _totalChildren;
  final Map<int, Profile> _children = {};

  Profiles.fromJson({
    required this.query,
    required Json json,
    this.startPage = 0,
  }) : _totalChildren = json["profiles"]["total"] {
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
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Map<String, String> parameters = {
      "q": query,
      "top": "true",
      "limit": _pageSize.toString(),
      "offset": (_pageSize * pageId).toString(),
    };

    Uri uri = Uri.https(
      HOST,
      "/api/v1/profiles",
      parameters,
    );

    Json json =
        await MicrocosmClient().getJson(uri, ttl: 3600, ignoreCache: force);
    parsePage(json);
  }

  // Uri get selfUrl => Uri.https(WEB_HOST, "/profiles/", {"top": "true"});

  @override
  void parsePage(Json json) {
    _totalChildren = json["profiles"]["total"];

    List<Profile> results = json["profiles"]["items"]
        .map<Profile>((item) => Profile.fromJson(json: item))
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
  Future<Profile> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ _pageSize);
    return _children[i]!;
  }

  @override
  Future<void> resetChildren({bool force = false}) async {
    await loadPage(0, force: force);
    _children.removeWhere((key, _) => key >= _pageSize);
  }
}
