import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../widgets/tiles/partial_profile_tile.dart';
import 'item.dart';
import 'profile.dart';

class PartialProfile extends Item {
  final int id;
  final String profileName;
  final bool visible;
  final String _avatar;

  String get avatar {
    // TODO: Pull domain from Site - don't hard-code it
    return _avatar.toString().startsWith('/')
        ? "https://lfgss.com$_avatar"
        : _avatar;
  }

  PartialProfile.fromJson({required Json json})
      : id = json["id"],
        profileName = HtmlUnescape().convert(json["profileName"]),
        visible = json["visible"],
        _avatar = json["avatar"];

  Future<Profile> getFullProfile() async {
    return Profile.getProfile(id);
  }

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return PartialProfileTile(partialProfile: this);
  }

  // So that Sets of profiles behave as expected...
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PartialProfile && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
