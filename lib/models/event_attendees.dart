import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/microcosm_client.dart';
import '../core/paginated.dart';
import 'profile.dart';

// TODO: refactor this whole file
// Maybe make it an ItemWithChildren

class EventAttendees implements Paginated<Profile> {
  final int eventId;
  final int attendeeCount;
  final int pageSize = 250;
  List<Profile>? attendees;

  EventAttendees({
    required this.eventId,
    required this.attendeeCount,
  });

  Future<List<Profile>> getPageOfChildren(int pageId) async {
    Uri uri = Uri.parse(
      "https://$API_HOST/api/v1/events/$eventId/attendees?limit=$pageSize&offset=${pageSize * pageId}",
    );

    Json json = await MicrocosmClient().getJson(uri);

    List<Profile> items = json["attendees"]["items"]
        .map<Profile>(
          (item) => Profile.fromJson(
            json: item["profile"],
          ),
        )
        .toList();

    return items;
  }

  Future<List<Profile>> getAttendeeList() async {
    attendees ??= await getPageOfChildren(0);
    return attendees!;
  }

  Widget getProfile(int index) {
    return FutureBuilder(
      future: getAttendeeList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // return const SizedBox(width: 100.0, height: 158.0);
          Profile profile = snapshot.data![index];
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
      profiles.add(getProfile(i));
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

  @override
  Widget childTile(int i) {
    // TODO: implement childTile
    throw UnimplementedError();
  }

  @override
  Future<Profile> getChild(int i) {
    // TODO: implement getChild
    throw UnimplementedError();
  }

  @override
  Future<void> loadPage(int pageId, {bool force = false}) {
    // TODO: implement loadOfChildren
    throw UnimplementedError();
  }

  @override
  void parsePage(Json json) {
    // TODO: implement parsePage
  }

  @override
  Future<void> resetChildren({bool force = false}) async {
    // TODO: implement resetChildren
    throw UnimplementedError();
  }

  @override
  // TODO: implement startPage
  int get startPage => throw UnimplementedError();

  @override
  int get totalChildren => attendeeCount;
}
