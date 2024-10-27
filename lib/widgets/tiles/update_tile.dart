import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:provider/provider.dart';

import '../../core/commentable_item.dart';
import '../../models/comment.dart';
import '../../models/conversation.dart';
import '../../models/huddle.dart';
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
      UpdateType.new_comment_in_huddle => _replyToHuddle(context),
      UpdateType.mentioned => _mention(context),
      _ => _standardUpdate()
    };
  }

  Widget _mention(BuildContext context) {
    final commentableItem = update.parent as CommentableItem;
    final comment = update.child as Comment;
    return _replyToCommentable(
      context,
      Icons.alternate_email,
      commentableItem,
      comment,
      "${comment.createdBy.profileName} mentioned you",
    );
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

  Future<void> _dismissNotification() =>
      FlutterLocalNotificationsPlugin().cancel(update.topicId);

  Widget _replyToComment(BuildContext context) {
    final conversation = update.parent as Conversation;
    final comment = update.child as Comment;
    return _replyToCommentable(
      context,
      Icons.reply_outlined,
      conversation,
      comment,
      "${comment.createdBy.profileName} replied to your comment",
    );
  }

  Widget _replyToHuddle(BuildContext context) {
    final huddle = update.parent as Huddle;
    final comment = update.child as Comment;
    return _replyToCommentable(
      context,
      Icons.reply_outlined,
      huddle,
      comment,
      "${comment.createdBy.profileName} sent a direct message",
    );
  }

  Widget _replyToCommentable(
    BuildContext context,
    IconData icon,
    CommentableItem commentableItem,
    Comment comment,
    String subtitle,
  ) {
    final unescape = HtmlUnescape();
    return Column(
      children: [
        Container(
          alignment: Alignment.bottomLeft,
          height: 28.0,
          padding: const EdgeInsets.only(left: 64.0),
          child: Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Card(
          key: ValueKey(commentableItem.id),
          child: InkWell(
            onTap: () async {
              _dismissNotification();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  maintainState: true,
                  builder: (context) => FutureScreen(
                    item: commentableItem.getItemByCommentId(
                      comment.id,
                    ),
                  ),
                ),
              );
            },
            child: ListTile(
              titleAlignment: ListTileTitleAlignment.top,
              leading: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 28,
                ),
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
                      unescape.convert(commentableItem.title),
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
