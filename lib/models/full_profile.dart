import 'package:html_unescape/html_unescape_small.dart';

import '../constants.dart';
import '../services/microcosm_client.dart';
import 'comment.dart';
import 'profile.dart';

class FullProfile extends Profile {
  final DateTime created;
  final String? email; // only visible for self
  final int itemCount;
  final int commentCount;

  final DateTime lastActive;
  final Comment? profileComment;
  final bool? member; // only visible for self
  // final int siteId; // not useful?
  // final int userId; // User has multiple Profiles. Only used for voting in polls
  // final bool visible; // is it ever false?
  // final int styleId = 0; // no idea

  FullProfile.fromJson({required Map<String, dynamic> json})
      : email = json["email"],
        itemCount = json["itemCount"],
        commentCount = json["commentCount"],
        created = DateTime.parse(json['created']),
        lastActive = DateTime.parse(json['lastActive']),
        member = json["member"],
        profileComment = json["comment"] == null
            ? null
            : Comment.fromJson(json: json["comment"]),
        super(
          id: json["id"],
          profileName: HtmlUnescape().convert(json["profileName"]),
          avatar: json["avatar"],
          visible: true,
        );

  static Future<FullProfile> getProfile([int id = 0]) async {
    Uri uri = Uri.parse(
      "https://$HOST/api/v1/${id == 0 ? 'whoami' : "profiles/$id"}",
    );

    Map<String, dynamic> json = await MicrocosmClient().getJson(uri);

    return FullProfile.fromJson(json: json);
  }
}