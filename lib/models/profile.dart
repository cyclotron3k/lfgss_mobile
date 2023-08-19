import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import '../api/microcosm_client.dart';
import '../constants.dart';
import 'comment.dart';
import 'item.dart';

class Profile extends Item {
  final int id;
  final String? email; // only visible for self
  final String profileName;
  final int itemCount;
  final int commentCount;
  final DateTime created;
  final DateTime lastActive;
  final String _avatar;
  final Comment? profileComment;
  final bool? member; // only visible for self
  // final int siteId; // not useful?
  // final int userId; // some other id?
  // final bool visible; // is it ever false?
  // final int styleId = 0; // no idea

  String get avatar {
    // TODO: Pull domain from Site - don't hard-code it
    return _avatar.toString().startsWith('/')
        ? "https://lfgss.com$_avatar"
        : _avatar;
  }

  Profile.fromJson({required Map<String, dynamic> json})
      : id = json["id"],
        // siteId = json["siteId"],
        email = json["email"],
        profileName = HtmlUnescape().convert(json["profileName"]),
        itemCount = json["itemCount"],
        commentCount = json["commentCount"],
        created = DateTime.parse(json['created']),
        lastActive = DateTime.parse(json['lastActive']),
        _avatar = json["avatar"],
        member = json["member"],
        profileComment = json["comment"] == null
            ? null
            : Comment.fromJson(json: json["comment"]);

  static Future<Profile> getProfile([int id = 0]) async {
    Uri uri = Uri.parse(
      "https://$HOST/api/v1/${id == 0 ? 'whoami' : "profile/$id"}",
    );

    Map<String, dynamic> json = await MicrocosmClient().getJson(uri);

    return Profile.fromJson(json: json);
  }

  @override
  // TODO: implement parent
  Item? get context => throw UnimplementedError();

  @override
  Widget renderAsTile({bool? overrideUnreadFlag}) {
    return const Placeholder();
  }
}
