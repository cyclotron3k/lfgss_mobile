import 'package:flutter/material.dart';

import '../widgets/partial_profile_tile.dart';
import 'item.dart';
import 'profile.dart';

typedef Json = Map<String, dynamic>;

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
        profileName = json["profileName"],
        visible = json["visible"],
        _avatar = json["avatar"];

  Future<Profile> getFullProfile() async {
    return Profile.getProfile(id);
  }

  @override
  // TODO: implement parent
  Item? get context => throw UnimplementedError();

  @override
  Widget renderAsTile() {
    return PartialProfileTile(partialProfile: this);
  }
}
