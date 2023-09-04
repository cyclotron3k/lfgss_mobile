import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/conversation.dart';
import '../models/profile.dart';
import '../models/search.dart';
import '../models/search_parameters.dart';
import '../widgets/future_conversation_screen.dart';
import '../widgets/future_search_screen.dart';
import '../widgets/profile_screen.dart';

class LinkParser {
  static final List<String> validSchemes = ['https', 'http', 'mailto', 'tel'];
  static final RegExp profileMatcher = RegExp(r'^/profiles/(\d+)$');
  static final RegExp hashtagMatcher = RegExp(r'^/search/\?q=(%23\w+)$');
  static final RegExp commentMatcher = RegExp(
    r'^(?:/api/v1)?/comments/(\d+)/?$',
  );

  static Future<void> parseLink(BuildContext context, String link) async {
    return _parse(context, link, Uri.parse(link));
  }

  static Future<void> parseUri(BuildContext context, Uri uri) async {
    return _parse(context, uri.toString(), uri);
  }

  static Future<void> _parse(BuildContext context, String link, Uri uri) async {
    if (profileMatcher.hasMatch(link)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => ProfileScreen(
            profile: Profile.getProfile(
              int.parse(
                profileMatcher.firstMatch(link)![1]!,
              ),
            ),
          ),
        ),
      );
      return;
    } else if (hashtagMatcher.hasMatch(link)) {
      String hashtag = Uri.decodeComponent(
        hashtagMatcher.firstMatch(link)![1]!,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => FutureSearchScreen(
            search: Search.search(
              searchParameters: SearchParameters(
                query: hashtag,
              ),
            ),
          ),
        ),
      );
      return;
    } else if (commentMatcher.hasMatch(link)) {
      int otherCommentId = int.parse(
        commentMatcher.firstMatch(link)![1]!,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => FutureConversationScreen(
            conversation: Conversation.getByCommentId(
              otherCommentId,
            ),
          ),
        ),
      );
      return;
    } else if (!validSchemes.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid URL: $uri"),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $link');
    }
  }
}
