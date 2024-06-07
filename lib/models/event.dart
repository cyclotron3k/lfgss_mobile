import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:timezone/timezone.dart' show Location, getLocation, TZDateTime;

import '../constants.dart';
import '../core/commentable_item.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/event_tile.dart';
import '../widgets/tiles/future_comment_tile.dart';
import 'attendee.dart';
import 'attendees.dart';
import 'comment.dart';
import 'flags.dart';
import 'permissions.dart';
import 'profile.dart';

enum EventStatus { proposed, upcoming, postponed, cancelled, past }

enum EventTiming { pending, active, expired, unknown }

class Event implements CommentableItem {
  @override
  final int startPage;

  @override
  final int id;

  @override
  final String title;
  final int microcosmId;

  // `when` and `whentz` are both presented as ISO 8601 timestamps.
  // They both appear to be in UTC, but only `whentz` is *actually* in UTC.
  final DateTime? when; // : "2022-10-14T21:00:00Z",
  final DateTime? whentz; // : "2022-10-14T20:00:00Z",
  final String tz; // : "Europe/London",

  final int? duration; // : 2880,
  final String? where; // : "Lee Valley Velodrome",
  final EventStatus status; // Unreliable. Always: "upcoming",
  final int rsvpLimit; // : 0,
  int rsvpAttend; // : 4,

  final double? lat; // 51.3972176057575
  final double? lon; // -0.039101243019104004
  final double? north; // 51.40498857403464
  final double? east; // -0.022144317626953125
  final double? south; // 51.39160107125888
  final double? west; // -0.055789947509765625

  // Metadata
  @override
  Flags flags;
  final DateTime? lastActivity;
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
        when = DateTime.tryParse(
          json["when"] ?? "",
        ),
        whentz = DateTime.tryParse(
          json["whentz"] ?? "",
        ),
        tz = json["tz"],
        duration = json["duration"],
        where = json["where"],
        status = EventStatus.values.byName(
          json["status"],
        ),
        rsvpLimit = json["rsvpLimit"],
        rsvpAttend = json["rsvpAttend"] ?? 0,
        lat = json["lat"],
        lon = json["lon"],
        north = json["north"],
        east = json["east"],
        south = json["south"],
        west = json["west"],
        createdBy = Profile.fromJson(json: json["meta"]["createdBy"]),
        // editedBy = Profile.fromJson(json: json["meta"]["editedBy"]),
        lastActivity = DateTime.tryParse(json["lastComment"]?["created"] ?? ""),
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
      API_HOST,
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

  // TODO: DRY
  @override
  Comment? getCachedComment(int commentId) => _children.values.firstWhereOrNull(
        (v) => v.id == commentId,
      );

  @override
  Future<Event> getItemByCommentId(int commentId) =>
      Event.getByCommentId(commentId);

  @override
  Future<Event> getByPageNo(
    int pageNo,
  ) async {
    int offset = (pageNo - 1) * 25;
    // incase we ever increase _our_ page size above 25:
    offset -= offset % PAGE_SIZE;

    Uri uri = Uri.https(
      API_HOST,
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

  Location? _location;
  get tzLocation => _location ??= getLocation(tz);

  TZDateTime? _tzStart;
  TZDateTime? get start {
    return whentz == null
        ? null
        : _tzStart ??= TZDateTime.from(
            whentz!,
            getLocation(tz),
          );
  }

  TZDateTime? _tzEnd;
  TZDateTime? get end {
    return _tzEnd ??= start?.add(Duration(minutes: duration ?? 0));
  }

  bool? get multiDay {
    if (when == null) return null;

    return start!.day != end!.day ||
        start!.month != end!.month ||
        start!.year != end!.year;
  }

  // This is necessary due to https://git.dee.kitchen/buro9/microcosm/issues/35
  EventTiming get timingStatus {
    if (whentz == null) return EventTiming.unknown;
    if (whentz!.isAfter(DateTime.now())) return EventTiming.pending;
    if (end!.isBefore(DateTime.now())) return EventTiming.expired;
    return EventTiming.active;
  }

  bool? equivalentTz() {
    if (whentz == null) return null;

    final myTZ = start!.toLocal();

    return start!.hour == myTZ.hour &&
        start!.day == myTZ.day &&
        start!.minute == myTZ.minute &&
        start!.month == myTZ.month &&
        start!.year == myTZ.year;
  }

  Attendees? _eventAttendees;

  bool hasAttendees() {
    return rsvpAttend > 0;
  }

  Future<Attendees> getAttendees() async {
    _eventAttendees ??= await Attendees.getByEventId(id);
    return _eventAttendees!;
  }

  Future<void> updateAttendance(int attendeeId, AttendeeStatus rsvp) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/events/$id/attendees",
    );

    await MicrocosmClient().putJson(
      uri,
      [
        {
          "profileId": attendeeId,
          "rsvp": rsvp.name,
        }
      ],
      followRedirects: false,
    );

    final attendees = await getAttendees();
    await attendees.resetChildren(force: true);
  }

  @override
  void parsePage(Json json) {
    _totalChildren = json["comments"]["total"];
    rsvpAttend = json["rsvpAttend"] ?? 0;
    flags = Flags.fromJson(json: json["meta"]["flags"]);

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

  static Future<Event> getById(int id, [int? offset]) async {
    String path =
        offset == null ? "/api/v1/events/$id/newcomment" : "/api/v1/events/$id";

    Uri uri = Uri.https(
      API_HOST,
      path,
      {
        if (offset != null) "offset": offset.toString(),
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
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/events/$id",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    final bool lastPage = pageId == totalChildren ~/ PAGE_SIZE;
    final int ttl = pageId == 0 || lastPage ? 5 : 3600;
    Json json = await MicrocosmClient().getJson(
      uri,
      ttl: ttl,
      ignoreCache: force,
    );
    parsePage(json);
  }

  @override
  Future<void> resetChildren({bool force = false, int? childId}) async {
    final int pageId;

    int index = -1;
    if (childId != null) {
      index = _children.keys.firstWhere(
        (k) => _children[k]!.id == childId,
        orElse: () => -1,
      );
    }

    if (index >= 0) {
      pageId = index ~/ PAGE_SIZE;
    } else {
      pageId = _totalChildren ~/ PAGE_SIZE;
    }

    await loadPage(pageId, force: true);
  }

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
    return EventTile(
      event: this,
      overrideUnreadFlag: overrideUnreadFlag,
    );
  }

  @override
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      var comment = _children[i]!;
      return comment.renderAsSingleComment(
        contextItem: this,
        highlight: highlight == comment.id,
      );
    }
    return FutureCommentTile(
      comment: getChild(i),
      contextItem: this,
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
      API_HOST,
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
      API_HOST,
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

  @override
  bool get canComment => flags.open && permissions.create;
}
