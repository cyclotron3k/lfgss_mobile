import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../models/profile.dart';
import '../../services/settings.dart';
import '../profile_sheet.dart';
import '../time_ago.dart';
import 'comment_html.dart';

class ProfileCommentTile extends StatelessWidget {
  final Comment comment;
  final Profile profile;
  final String highlight;
  final bool? overrideUnreadFlag;

  const ProfileCommentTile({
    super.key,
    required this.comment,
    required this.profile,
    required this.highlight,
    this.overrideUnreadFlag,
  });

  Future<void> _showProfileModal(BuildContext context) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => ProfileSheet(
          profile: profile,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(comment.id),
      child: InkWell(
        onTap: () => _showProfileModal(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      "${profile.profileName}'s profile",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(children: [
              Container(
                width: 38.0,
                padding: const EdgeInsets.all(8.0),
                child: CachedNetworkImage(
                  imageUrl: comment.createdBy.avatar,
                  width: 22,
                  height: 22,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person_outline,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4.0,
                  children: [
                    Text(comment.createdBy.profileName),
                  ],
                ),
              ),
              Expanded(
                child: Wrap(
                  runAlignment: WrapAlignment.end,
                  alignment: WrapAlignment.end,
                  spacing: 4.0,
                  children: [
                    TimeAgo(
                      comment.created,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
            ]),
            Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: 8.0,
              ),
              child: _commentBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentBody() {
    if (highlight == "") {
      return Consumer<Settings>(
        builder: (context, settings, _) => CommentHtml(
          html: comment.html,
          selectable: false,
          embedTweets: settings.getBool("embedTweets") ?? true,
          embedYouTube: settings.getBool("embedYouTube") ?? true,
        ),
      );
    }

    return CommentHtml(
      html: highlight,
      selectable: false,
      embedTweets: false,
      embedYouTube: false,
    );
  }
}
