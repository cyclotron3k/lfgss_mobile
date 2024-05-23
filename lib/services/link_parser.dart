import 'package:flutter/material.dart';
import 'package:lfgss_mobile/core/commentable_item.dart';
import 'package:lfgss_mobile/models/huddle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/conversation.dart';
import '../models/event.dart';
import '../models/full_profile.dart';
import '../models/search.dart';
import '../widgets/link_preview.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/screens/future_screen.dart';
import '../widgets/screens/future_search_results_screen.dart';

class LinkParser {
  static Future<Object?> parseLink(BuildContext context, String link) async {
    return _parse(context, Uri.parse(link));
  }

  static Future<Object?> parseUri(BuildContext context, Uri uri) async {
    return _parse(context, uri);
  }

  static final List<String> validSchemes = ['https', 'http', 'mailto', 'tel'];

  static final conversationIndicator = RegExp(r'/conversations/');
  static final eventIndicator = RegExp(r'/events/');
  static final huddleIndicator = RegExp(r'/huddles/');
  static final fragments = RegExp(r'^comment(\d+)$');
  static final profileMatcher = RegExp(r'^/profiles/(\d+)$');
  static final searchMatcher = RegExp(r'^/search/');
  static final commentMatcher = RegExp(
    r'^(?:/api/v1)?/comments/(\d+)(?:/incontext)?/?$',
  );
  static final matcher = RegExp(
    r'^(?:/api/v1)?/(conversations|events|huddles)/(\d+)(?:/newest)?/?$',
  );

  static Future<Object?> _push(BuildContext context, Widget widget) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          maintainState: true,
          builder: (context) => widget,
        ),
      );

  static Future<Object?> _parse(BuildContext context, Uri uri) async {
    if (!uri.hasAuthority || uri.host == WEB_HOST) {
      // it's an internal link
      var match = fragments.firstMatch(uri.fragment) ??
          commentMatcher.firstMatch(uri.path);

      if (match != null) {
        final id = int.parse(match[1]!);

        if (eventIndicator.hasMatch(uri.path)) {
          return _push(
            context,
            FutureScreen(
              item: Event.getByCommentId(id),
            ),
          );
        } else if (huddleIndicator.hasMatch(uri.path)) {
          return _push(
            context,
            FutureScreen(
              item: Huddle.getByCommentId(id),
            ),
          );
        } else {
          // default to "conversation"
          return _push(
            context,
            FutureScreen(
              item: Conversation.getByCommentId(id),
            ),
          );
        }
      }

      match = matcher.firstMatch(uri.path);
      if (match != null) {
        final type = match[1]!;
        final id = int.parse(match[2]!);

        final int? offset;
        if (uri.queryParameters.containsKey("offset")) {
          offset = int.parse(uri.queryParameters["offset"] ?? "0");
        } else {
          offset = null;
        }

        final Future<CommentableItem> widget = switch (type) {
          "events" => Event.getById(id, offset),
          "huddles" => Huddle.getById(id, offset),
          _ => Conversation.getById(id, offset),
        };

        return _push(
          context,
          FutureScreen(
            item: widget,
          ),
        );
      }

      match = profileMatcher.firstMatch(uri.path);
      if (match != null) {
        var fp = await FullProfile.getProfile(
          int.parse(
            profileMatcher.firstMatch(uri.path)![1]!,
          ),
          true,
        );

        if (!context.mounted) return null;

        await showModalBottomSheet<void>(
          enableDrag: true,
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) => ProfileSheet(
            profile: fp,
          ),
        );

        return null;
      }

      match = searchMatcher.firstMatch(uri.path);
      if (match != null) {
        return _push(
          context,
          FutureSearchResultsScreen(
            search: Search.searchWithUri(
              uri,
            ),
          ),
        );
      }
    }

    if (!validSchemes.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid URL: $uri"),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    final sp = await SharedPreferences.getInstance();
    final previewUrls = sp.getBool('previewUrls') ?? false;
    if (!context.mounted) return null;
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
        throw Exception('Could not launch $uri');
      }
    }
    return null;
  }
}
