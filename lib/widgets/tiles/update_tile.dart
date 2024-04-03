import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../models/conversation.dart';
import '../../models/update.dart';
import '../../models/update_type.dart';
import '../../services/settings.dart';
import '../screens/future_screen.dart';
import '../time_ago.dart';
import 'comment_html.dart';

class UpdateTile extends StatelessWidget {
  final Update update;

  const UpdateTile({
    super.key,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    return switch (update.updateType) {
      UpdateType.reply_to_comment => _replyToComment(context),
      _ => _standardUpdate()
    };
  }

  Widget _standardUpdate() => Column(
        children: [
          Container(
            alignment: Alignment.bottomLeft,
            height: 28.0,
            padding: const EdgeInsets.only(left: 64.0),
            child: Text(
              update.description,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          update.parent.renderAsTile(
            overrideUnreadFlag: update.flags.unread,
            isReply: update.updateType == UpdateType.reply_to_comment,
            mentioned: update.updateType == UpdateType.mentioned,
          ),
        ],
      );

  Widget _replyToComment(BuildContext context) {
    final unescape = HtmlUnescape();
    final conversation = update.parent as Conversation;
    final comment = update.child as Comment;
    return Column(
      children: [
        Container(
          alignment: Alignment.bottomLeft,
          height: 28.0,
          padding: const EdgeInsets.only(left: 64.0),
          child: Text(
            "${comment.createdBy.profileName} replied to your comment",
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Card(
          key: ValueKey(conversation.id),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  maintainState: true,
                  builder: (context) => FutureScreen(
                    item: Conversation.getByCommentId(
                      comment.id,
                    ),
                  ),
                ),
              );
            },
            child: ListTile(
              leading: Icon(
                color: Theme.of(context).colorScheme.inversePrimary,
                Icons.reply_outlined,
                size: 28,
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.flags.unread)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 6.0, 6.0, 6.0),
                      child: Icon(
                        Icons.circle,
                        size: 10.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      unescape.convert(conversation.title),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                children: [
                  Consumer<Settings>(
                    builder: (context, settings, _) => CommentHtml(
                      html: comment.html,
                      selectable: false,
                      embedTweets: settings.getBool("embedTweets") ?? true,
                      embedYouTube: settings.getBool("embedYouTube") ?? true,
                      replyTarget: comment,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TimeAgo(comment.created),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
