import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:provider/provider.dart';

import '../../core/commentable.dart';
import '../../models/comment.dart';
import '../../services/link_parser.dart';
import '../../services/settings.dart';
import '../profile_sheet.dart';
import '../screens/future_screen.dart';
import '../time_ago.dart';
import 'comment_html.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final CommentableItem context;
  final String highlight;
  final bool? overrideUnreadFlag;

  const CommentTile({
    super.key,
    required this.comment,
    required this.context,
    required this.highlight,
    this.overrideUnreadFlag,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  Future<void> _showProfileModal(BuildContext context) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => ProfileSheet(
          profile: widget.comment.createdBy,
        ),
      );

  @override
  Widget build(BuildContext context) {
    bool showReplied = widget.comment.links.containsKey("inReplyToAuthor");

    return Card(
      key: ValueKey(widget.comment.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureScreen(
                item: widget.comment.container,
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
                    widget.comment.itemType == 'huddle'
                        ? Icons.mail_outline
                        : Icons.chat,
                    size: 14.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      widget.context.title,
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
                  imageUrl: widget.comment.createdBy.avatar,
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
                        widget.comment.createdBy.profileName,
                      ),
                    ),
                    if (showReplied)
                      InkWell(
                        onTap: () async {
                          LinkParser.parseUri(
                            context,
                            widget.comment.links["inReplyTo"]!.href,
                          );
                        },
                        child: Text(
                          "replied to ${HtmlUnescape().convert(widget.comment.links["inReplyToAuthor"]!.title ?? "")}",
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
                    TimeAgo(widget.comment.created, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
            ]),
            _commentBody(),
          ],
        ),
      ),
    );
  }

  Widget _commentBody() {
    if (widget.highlight == "") {
      return Consumer<Settings>(
        builder: (context, settings, _) => CommentHtml(
          html: widget.comment.html,
          embedTweets: settings.getBool("embedTweets") ?? true,
          embedYouTube: settings.getBool("embedYouTube") ?? true,
          replyTarget: widget.comment,
        ),
      );
    }

    return Consumer<Settings>(
      builder: (context, settings, _) => CommentHtml(
        html: widget.highlight,
        embedTweets: false,
        embedYouTube: false,
      ),
    );
  }
}
