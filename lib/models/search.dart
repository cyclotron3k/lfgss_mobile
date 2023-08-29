import 'package:flutter/material.dart';

import '../api/microcosm_client.dart' hide Json;
import '../constants.dart';
import '../widgets/future_item_tile.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'search_parameters.dart';
import 'search_result.dart';
import 'unknown_item.dart';

class Search extends ItemWithChildren {
  SearchParameters searchParameters;

  final int _totalChildren;
  final Map<int, Item> _children = {};

  Search.fromJson({required this.searchParameters, required Json json})
      : _totalChildren = json["results"]["total"] {
    parsePage(json);
  }

  static Future<Search> today() {
    return search(
      searchParameters: SearchParameters(
        query: "",
        since: -1,
        type: {'conversation', 'event', 'profile', 'huddle'},
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

    Json json = await MicrocosmClient().getJson(uri, ttl: 5);
    parsePage(json);
  }

  @override
  void parsePage(Json json) {
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
    // TODO: implement renderAsTile
    return const Placeholder();
  }
}
