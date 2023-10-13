import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/future_item_tile.dart';
import '../core/item.dart';
import '../core/paginated.dart';
import 'search_parameters.dart';
import 'search_result.dart';

class Search implements Paginated<SearchResult> {
  @override
  final int startPage;
  SearchParameters searchParameters;

  int _totalChildren;
  final Map<int, SearchResult> _children = {};

  Search.fromJson({
    required this.searchParameters,
    required Json json,
    this.startPage = 0,
  }) : _totalChildren = json["results"]["total"] {
    parsePage(json);
  }

  static Future<Search> today() {
    return search(
      searchParameters: SearchParameters(
        query: "",
        since: -1,
        type: {
          SearchType.conversation,
          SearchType.event,
          SearchType.profile,
          SearchType.huddle,
        },
      ),
    );
  }

  static Future<Search> searchWithUri(Uri uri) {
    return search(
      searchParameters: SearchParameters.fromUri(
        uri,
      ),
    );
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

    Json json = await MicrocosmClient().getJson(uri, ttl: 5);

    return Search.fromJson(
      searchParameters: searchParameters,
      json: json,
    );
  }

  Uri get selfUrl => Uri.https(
        WEB_HOST,
        "/search/",
        searchParameters.asQueryParameters,
      );

  @override
  int get totalChildren {
    return _totalChildren;
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    var parameters = searchParameters.asQueryParameters;
    parameters["limit"] = PAGE_SIZE.toString();
    parameters["offset"] = (PAGE_SIZE * pageId).toString();

    Uri uri = Uri.https(
      HOST,
      "/api/v1/search",
      parameters,
    );

    Json json =
        await MicrocosmClient().getJson(uri, ttl: 5, ignoreCache: force);
    parsePage(json);
  }

  @override
  void parsePage(Json json) {
    _totalChildren = json["results"]["total"];

    List<SearchResult> results = json["results"]["items"]
        .map<SearchResult>((item) => SearchResult.fromJson(item))
        .toList();

    for (final (index, item) in results.indexed) {
      _children[json["results"]["offset"] + index] = item;
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
  Future<SearchResult> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ PAGE_SIZE);
    return _children[i]!;
  }

  @override
  Future<void> resetChildren({bool force = false}) async {
    await loadPage(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
  }
}
