// import 'package:collection/collection.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../constants.dart';
// import '../services/microcosm_client.dart' hide Json;
// import '../core/item.dart';
// import 'update.dart';

// class UpdatesNotifier extends ChangeNotifier {

//   final int startPage;
//   int _totalChildren;
//   final List<Update?> _children = [];

//   UpdatesNotifier.fromJson({
//     required Json json,
//     this.startPage = 0,
//   }) : _totalChildren = json["updates"]["total"] {
//     parsePage(json);
//   }

//   static Future<UpdatesNotifier> root({int pageSize = PAGE_SIZE}) async {
//     var uri = Uri.https(
//       API_HOST,
//       "/api/v1/updates",
//       {"limit": pageSize.toString(), "offset": "0"},
//     );

//     Json json = await MicrocosmClient().getJson(uri, ttl: 5);

//     return UpdatesNotifier.fromJson(json: json);
//   }

//   int get totalChildren => _totalChildren;

//   Uri get selfUrl => Uri.https(
//         WEB_HOST,
//         "/updates/",
//       );

//   Future<List<Update>> getNewUpdates() async {
//     final sharedPreference = await SharedPreferences.getInstance();

//     final int? spUpdateId = sharedPreference.getInt("lastUpdateId");

//     // Only show updates newer than this:
//     final int lastUpdateId = spUpdateId ?? _highTide ?? 0;

//     final Iterable<Update> newUpdates = _children.values.where(
//       (update) => update.id > lastUpdateId && update.flags.unread,
//     );

//     if (newUpdates.isNotEmpty || spUpdateId != lastUpdateId) {
//       int id = newUpdates.isNotEmpty ? newUpdates.first.id : lastUpdateId;
//       await sharedPreference.setInt(
//         "lastUpdateId",
//         id,
//       );
//     }

//     return newUpdates.toList();
//   }

//   int? get _highTide {
//     Update? lastUpdate = maxBy<Update, int>(_children.values, (c) => c.id);
//     if (lastUpdate != null) {
//       return lastUpdate.id;
//     }
//     return null;
//   }

//   Future<void> loadPage(int pageId, {bool force = false}) async {
//     Uri uri = Uri.https(
//       API_HOST,
//       "/api/v1/updates",
//       {
//         "limit": PAGE_SIZE.toString(),
//         "offset": (PAGE_SIZE * pageId).toString(),
//       },
//     );

//     Json json =
//         await MicrocosmClient().getJson(uri, ttl: 5, ignoreCache: force);
//     parsePage(json);
//   }

//   void parsePage(Json json) {
//     _totalChildren = json["updates"]["total"];
//     List<Update> items = json["updates"]["items"]
//         .map<Update>((item) => Update.fromJson(item))
//         .toList();

//     for (final (index, item) in items.indexed) {
//       _children[json["updates"]["offset"] + index] = item;
//     }
//   }

//   void requestPage(int i) {
//     // is the page in flight?
//   }


//   Item? getChild(int i) {
//     if (i < _children.length) {
//       if (_children[i] == null) {
//         loadPage(i ~/ PAGE_SIZE);
//       }
//       return _children[i];
//     }
//     return null;
//   }
// }
