import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
// import 'package:timezone/data/latest_10y.dart';

import 'event_attendees.dart';
import 'partial_profile.dart';
import 'unknown_item.dart';
import '../api/microcosm_client.dart';
import '../constants.dart';
import '../widgets/event_tile.dart';
import '../widgets/future_item_tile.dart';
import 'comment.dart';
import 'flags.dart';
import 'item.dart';
import 'item_with_children.dart';
import 'permissions.dart';

enum EventStatus { proposed, upcoming, postponed, cancelled }

typedef Json = Map<String, dynamic>;

class Event implements ItemWithChildren {
  final int startPage;

  final int id;
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
  final Flags flags;
  final Permissions permissions;
  final PartialProfile createdBy;
  // final Profile editedBy;
  final DateTime created;

  final int _totalChildren;
  final Map<int, Item> _children = {};

  Event.fromJson({required Map<String, dynamic> json, this.startPage = 0})
      : id = json["id"],
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
        createdBy = PartialProfile.fromJson(json: json["meta"]["createdBy"]),
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
  Future<void> getPageOfChildren(int i) async {
    Uri uri = Uri.https(
      HOST,
      "/api/v1/events/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * i).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);
    parsePage(json);
  }

  Item? _context;

  @override
  set context(Item? tmp) {
    _context = tmp;
  }

  @override
  Item? get context => _context;

  @override
  Future<void> resetChildren() async {
    await getPageOfChildren(0);
    _children.removeWhere((key, _) => key >= PAGE_SIZE);
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
}
