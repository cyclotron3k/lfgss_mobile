import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/conversation.dart';
import '../models/event.dart';
import '../models/full_profile.dart';
import '../models/search.dart';
import '../widgets/link_preview.dart';
import '../widgets/screens/future_screen.dart';
import '../widgets/screens/future_search_screen.dart';
import '../widgets/screens/profile_screen.dart';

class LinkParser {
  static final List<String> validSchemes = ['https', 'http', 'mailto', 'tel'];
  static final RegExp profileMatcher = RegExp(r'^/profiles/(\d+)$');
  static final RegExp searchMatcher = RegExp(r'^/search/');
  static final RegExp commentMatcher = RegExp(
    r'^(?:/api/v1)?/comments/(\d+)/?$',
  );
  static final RegExp conversationMatcher = RegExp(
    r'^(?:/api/v1)?/conversations/(\d+)(?:(?:/newest)?/)?$',
  );
  static final RegExp eventMatcher = RegExp(
    r'^(?:/api/v1)?/events/(\d+)(?:(?:/newest)?/)?$',
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
            profile: FullProfile.getProfile(
              int.parse(
                profileMatcher.firstMatch(link)![1]!,
              ),
            ),
          ),
        ),
      );
      return;
    } else if (searchMatcher.hasMatch(link)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => FutureSearchScreen(
            search: Search.searchWithUri(
              uri,
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
          builder: (context) => FutureScreen(
            item: Conversation.getByCommentId(
              otherCommentId,
            ),
          ),
        ),
      );
      return;
    } else if (conversationMatcher.hasMatch(link)) {
      int conversationId = int.parse(
        conversationMatcher.firstMatch(link)![1]!,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => FutureScreen(
            item: Conversation.getById(
              conversationId,
            ),
          ),
        ),
      );
      return;
    } else if (eventMatcher.hasMatch(link)) {
      int eventId = int.parse(
        eventMatcher.firstMatch(link)![1]!,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => FutureScreen(
            item: Event.getById(
              eventId,
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

    final sp = await SharedPreferences.getInstance();
    final previewUrls = sp.getBool('previewUrls') ?? false;
    if (!context.mounted) return;
    String? action = "go";
    if (previewUrls) {
      action = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("URL Preview"),
            content: LinkPreview(primary: uri),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop<String>(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () => Navigator.pop<String>(context, "go"),
                child: const Text("GO"),
              ),
            ],
          );
        },
      );
    }
    if (action == "go") {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $link');
      }
    }
  }
}
