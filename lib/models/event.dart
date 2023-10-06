import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/commentable.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/event_tile.dart';
import '../widgets/tiles/future_comment_tile.dart';
import 'comment.dart';
// import 'package:timezone/data/latest_10y.dart';

import 'event_attendees.dart';
import 'flags.dart';
import 'permissions.dart';
import 'profile.dart';

enum EventStatus { proposed, upcoming, postponed, cancelled }

class Event implements CommentableItem {
  @override
  final int startPage;

  @override
  final int id;

  @override
  final String title;
  final int microcosmId;

  final DateTime when; // : "2022-10-14T21:00:00Z",
  final String tz; // : "Europe/London",
  // final int whentz; // : "2022-10-14T20:00:00Z",
  final int duration; // : 2880,
  final String where; // : "Lee Valley Velodrome",
  final EventStatus status; // : "upcoming",
  final int rsvpLimit; // : 0,
  final int rsvpAttend; // : 4,

  final double? lat; // 51.3972176057575
  final double? lon; // -0.039101243019104004
  final double? north; // 51.40498857403464
  final double? east; // -0.022144317626953125
  final double? south; // 51.39160107125888
  final double? west; // -0.055789947509765625

  // Metadata
  @override
  final Flags flags;
  final Permissions permissions;
  @override
  final Profile createdBy;
  // final Profile editedBy;
  @override
  final DateTime created;

  int _totalChildren;
  final Map<int, Comment> _children = {};

  final int highlight;

  Event.fromJson({
    required Map<String, dynamic> json,
    this.startPage = 0,
    this.highlight = 0,
  })  : id = json["id"],
        title = HtmlUnescape().convert(json["title"]),
        microcosmId = json["microcosmId"],
        when = DateTime.parse(
          json["when"],
        ), // DateTime: "2022-10-14T21:00:00Z",
        tz = json["tz"], // String: "Europe/London",
        duration = json["duration"], // int: 2880,
        where = json["where"], // String: "Lee Valley Velodrome",
        status = EventStatus.values.byName(
          json["status"],
        ), // EventStatus: "upcoming",
        rsvpLimit = json["rsvpLimit"], // int: 0,
        rsvpAttend = json["rsvpAttend"] ?? 0, // int: 4,
        lat = json["lat"],
        lon = json["lon"],
        north = json["north"],
        east = json["east"],
        south = json["south"],
        west = json["west"],
        createdBy = Profile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json["meta"]["editedBy"]),
        created = DateTime.parse(json["meta"]["created"]),
        flags = Flags.fromJson(json: json["meta"]["flags"]),
        permissions = Permissions.fromJson(
          json: json["meta"]["permissions"] ?? {},
        ),
        _totalChildren = json["comments"]?["total"] ?? json["totalComments"] {
    if (json.containsKey("comments")) {
      parsePage(json);
    }
  }

  static Future<Event> getByCommentId(int commentId) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/comments/$commentId/incontext",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Event.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
      highlight: commentId,
    );
  }

  @override
  Future<Event> getByPageNo(
    int pageNo,
  ) async {
    int offset = (pageNo - 1) * 25;
    // incase we ever increase _our_ page size above 25:
    offset -= offset % PAGE_SIZE;

    Uri uri = Uri.https(
      HOST,
      "/api/v1/events/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": offset.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Event.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
    );
  }

  DateTime get whenEnd {
    return when.add(Duration(minutes: duration));
  }

  EventAttendees? _eventAttendees;

  bool hasAttendees() {
    return rsvpAttend > 0;
  }

  Widget getAttendees() {
    _eventAttendees ??= EventAttendees(
      eventId: id,
      attendeeCount: rsvpAttend,
    );
    return _eventAttendees!.build();
  }

  @override
  void parsePage(Json json) {
    _totalChildren = json["comments"]["total"];

    List<Comment> comments = json["comments"]["items"]
        .map<Comment>(
          (comment) => Comment.fromJson(json: comment),
        )
        .toList();

    for (final (index, comment) in comments.indexed) {
      _children[json["comments"]["offset"] + index] = comment;
    }
  }

  @override
  int get totalChildren => _totalChildren;

  @override
  Uri get selfUrl => Uri.https(
        WEB_HOST,
        "/events/$id/newest",
      );

  static Future<Event> getById(int id) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/events/$id/newcomment",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return Event.fromJson(
      json: json,
      startPage: json["comments"]["page"] - 1,
    );
  }

  @override
  Future<void> loadPage(int i) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/events/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * i).toString(),
      },
    );

    final bool lastPage = i == totalChildren ~/ PAGE_SIZE;
    final int ttl = i == 0 || lastPage ? 5 : 3600;
    Json json = await MicrocosmClient().getJson(uri, ttl: ttl);
    parsePage(json);
  }

  @override
  Future<void> resetChildren() async {
    final int lastPage = _totalChildren ~/ PAGE_SIZE;
    await loadPage(lastPage);
    _children.removeWhere((key, _) => key >= lastPage * PAGE_SIZE);
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return EventTile(
      event: this,
      overrideUnreadFlag: overrideUnreadFlag,
    );
  }

  @override
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      var comment = _children[i]!;
      return comment.renderAsTile(highlight: highlight == comment.id);
    }
    return FutureCommentTile(
      comment: getChild(i),
      highlight: highlight,
    );
  }

  @override
  Future<Comment> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ PAGE_SIZE);
    return _children[i]!;
  }

  @override
  Future<bool> subscribe() async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/watchers",
    );

    final response = await MicrocosmClient().post(uri, {
      "itemType": "event",
      "itemId": id,
      "updateTypeId": 1,
    });
    final bool success = response.statusCode == 200;
    if (success) flags.watched = true;
    return success;
  }

  @override
  Future<bool> unsubscribe() async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/watchers/delete",
      {
        "updateTypeId": "1",
        "itemId": id.toString(),
        "itemType": "event",
      },
    );

    final response = await MicrocosmClient().delete(uri);
    final bool success = response.statusCode == 200;
    if (success) flags.watched = false;
    return success;
  }
}
