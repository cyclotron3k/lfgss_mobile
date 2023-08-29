import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/microcosm_client.dart';
import '../constants.dart';
import 'partial_profile.dart';

// TODO refactor this whole file
// Maybe make it an ItemWithChildren

class EventAttendees {
  final int eventId;
  final int attendeeCount;
  final int pageSize = 250;
  List<PartialProfile>? attendees;

  EventAttendees({
    required this.eventId,
    required this.attendeeCount,
  });

  Future<List<PartialProfile>> getPageOfChildren(int pageId) async {
    Uri uri = Uri.parse(
      "https://$HOST/api/v1/events/$eventId/attendees?limit=$pageSize&offset=${pageSize * pageId}",
    );

    Json json = await MicrocosmClient().getJson(uri);

    List<PartialProfile> items = json["attendees"]["items"]
        .map<PartialProfile>(
          (item) => PartialProfile.fromJson(
            json: item["profile"],
          ),
        )
        .toList();

    return items;
  }

  Future<List<PartialProfile>> getAttendeeList() async {
    attendees ??= await getPageOfChildren(0);
    return attendees!;
  }

  Widget getPartialProfile(int index) {
    return FutureBuilder(
      future: getAttendeeList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // return const SizedBox(width: 100.0, height: 158.0);
          PartialProfile profile = snapshot.data![index];
          return Chip(
            avatar: CircleAvatar(
              foregroundImage: CachedNetworkImageProvider(profile.avatar),
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.person),
            ),
            label: Text(profile.profileName),
          );
        } else if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 24.0,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget build() {
    List<Widget> profiles = [];

    for (int i = 0; i < attendeeCount; i++) {
      profiles.add(getPartialProfile(i));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Attendees ($attendeeCount)"),
        ),
        Wrap(
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 4.0, //
          children: profiles,
        )
      ],
    );
  }
}
