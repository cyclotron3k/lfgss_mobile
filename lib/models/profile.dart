import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../core/item.dart';
import '../services/microcosm_client.dart' hide Json;
import '../widgets/tiles/profile_tile.dart';
import 'flags.dart';
import 'full_profile.dart';

class Profile implements Item {
  @override
  final int id;
  final String profileName;
  final bool visible;
  final String _avatar;

  Profile({
    required this.id,
    required this.profileName,
    required this.visible,
    required String avatar,
  }) : _avatar = avatar;

  Profile.fromJson({required Json json})
      : id = json["id"],
        profileName = HtmlUnescape().convert(json["profileName"]),
        visible = json["visible"],
        _avatar = json["avatar"];

  String get avatar => _avatar.toString().startsWith('/')
      ? "https://$API_HOST$_avatar"
      : _avatar;

  Future<bool> get isBlocked async {
    return false;
  }

  Future<void> ignore() async {
    var uri = Uri.https(
      API_HOST,
      "/api/v1/ignored",
    );

    await MicrocosmClient().put(uri, {
      "itemType": "profile",
      "itemId": id,
    });

    return;
  }

  Future<void> unignore() async {
    var uri = Uri.https(
      API_HOST,
      "/api/v1/ignored",
    );

    await MicrocosmClient().delete(uri, {
      "itemType": "profile",
      "itemId": id,
    });

    return;
  }

  Future<FullProfile> getFullProfile({bool ignoreCache = false}) async {
    return FullProfile.getProfile(id, ignoreCache);
  }

  @override
  Widget renderAsTile({
    bool? overrideUnreadFlag,
    bool? isReply,
    bool? mentioned,
  }) {
    return ProfileTile(profile: this);
  }

  // So that Sets of profiles behave as expected...
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  Uri get selfUrl => Uri.https(WEB_HOST, "/profiles/$id/");

  @override
  Flags get flags => throw UnimplementedError();
}
