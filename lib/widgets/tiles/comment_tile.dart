import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:provider/provider.dart';

import '../../core/commentable_item.dart';
import '../../models/comment.dart';
import '../../services/settings.dart';
import '../profile_sheet.dart';
import '../screens/future_screen.dart';
import '../thread_view.dart';
import '../time_ago.dart';
import 'comment_html.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final CommentableItem contextItem;
  final String highlight;
  final bool? overrideUnreadFlag;

  const CommentTile({
    super.key,
    required this.comment,
    required this.contextItem,
    required this.highlight,
    this.overrideUnreadFlag,
  });

  Future<void> _showProfileModal(BuildContext context) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => ProfileSheet(
          profile: comment.createdBy,
        ),
      );

  @override
  Widget build(BuildContext context) {
    bool showReplied = comment.links.containsKey("inReplyToAuthor");

    return Card(
      key: ValueKey(comment.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureScreen(
                item: comment.container,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    comment.itemType == 'huddle'
                        ? Icons.mail_outline
                        : Icons.chat,
                    size: 14.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      contextItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: const TextStyle(color: Colors.grey),
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
                flex: showReplied ? 2 : 1,
                child: Wrap(
                  spacing: 4.0,
                  children: [
                    InkWell(
                      onTap: () => _showProfileModal(context),
                      child: Text(
                        comment.createdBy.profileName,
                      ),
                    ),
                    if (showReplied)
                      InkWell(
                        onTap: () => showDialog(
                          context: context,
                          builder: (BuildContext context) => Dialog(
                            clipBehavior: Clip.hardEdge,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: ThreadView(
                                  rootComment: comment,
                                  commentableItem: contextItem,
                                ),
                              ),
                            ),
                          ),
                        ),
                        child: Text(
                          "replied to ${HtmlUnescape().convert(comment.links["inReplyToAuthor"]!.title ?? "")}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Wrap(
                  runAlignment: WrapAlignment.end,
                  alignment: WrapAlignment.end,
                  spacing: 4.0,
                  children: [
                    TimeAgo(comment.created, color: Colors.grey),
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
          replyTarget: comment,
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
