import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/microcosm_client.dart';
import '../core/paginated.dart';
import '../widgets/attendee_chip.dart';
import '../widgets/attendee_shimmer.dart';
import 'attendee.dart';

class EventAttendees implements Paginated<Attendee> {
  final int eventId;
  @override
  final int startPage;
  @override
  int totalChildren;

  final Map<int, Attendee> _children = {};

  EventAttendees.fromJson({
    required this.eventId,
    required Json json,
    this.startPage = 0,
  }) : totalChildren = json["attendees"]["total"] {
    if (json.containsKey("items")) {
      parsePage(json);
    }
  }

  @override
  void parsePage(Json json) {
    totalChildren = json["attendees"]["total"];

    List<Attendee> attendees = json["attendees"]["items"]
        .map<Attendee>(
          (attendee) => Attendee.fromJson(json: attendee),
        )
        .toList();

    for (final (index, attendee) in attendees.indexed) {
      _children[json["attendees"]["offset"] + index] = attendee;
    }
  }

  static Future<EventAttendees> getByEventId(int eventId) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/events/$eventId/attendees",
      {
        "limit": PAGE_SIZE.toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri);

    return EventAttendees.fromJson(
      eventId: eventId,
      json: json,
      startPage: json["attendees"]["page"] - 1,
    );
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/events/$eventId/attendees",
      {
        "limit": PAGE_SIZE.toString(),
        "offset": (PAGE_SIZE * pageId).toString(),
      },
    );

    final bool lastPage = pageId == totalChildren ~/ PAGE_SIZE;
    final int ttl = lastPage ? 5 : 3600;

    Json json = await MicrocosmClient().getJson(
      uri,
      ttl: ttl,
      ignoreCache: force,
    );
    parsePage(json);
  }

  @override
  Future<void> resetChildren({bool force = false, int? childId}) async {
    // With an attendee list we're not just appending new content,
    // we're modifying the items on the list. So we can't just
    // proactively request empty pages to see if there's new content.
    final int pageId = (totalChildren - 1) ~/ PAGE_SIZE;

    await loadPage(pageId, force: force);
  }

  @override
  Widget childTile(int i) {
    if (_children.containsKey(i)) {
      return AttendeeChip(attendee: _children[i]!);
    }
    return FutureBuilder<Attendee>(
      future: getChild(i),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AttendeeChip(attendee: snapshot.data!);
        } else if (snapshot.hasError) {
          // TODO: something that indicates error
          return const AttendeeShimmer();
        } else {
          return const AttendeeShimmer();
        }
      },
    );
  }

  @override
  Future<Attendee> getChild(int i) async {
    if (_children.containsKey(i)) {
      return _children[i]!;
    }
    await loadPage(i ~/ PAGE_SIZE);
    return _children[i]!;
  }
}
