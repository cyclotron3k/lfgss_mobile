import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';

import '../../models/conversation.dart';
import '../screens/future_screen.dart';
import '../time_ago.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool? overrideUnreadFlag;
  final bool? isReply;
  final bool? mentioned;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.overrideUnreadFlag,
    this.isReply,
    this.mentioned,
  });

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Card(
      key: ValueKey(conversation.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureScreen(
                item: Conversation.getById(conversation.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: leadingIcon(context),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overrideUnreadFlag ?? conversation.flags.unread)
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
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (conversation.lastActivity != null)
                TimeAgo(conversation.lastActivity!),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.chat,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 15.0,
                ),
              ),
              Text(
                NumberFormat.compact().format(
                  conversation.totalChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Icon leadingIcon(BuildContext context) {
    if (isReply == true) {
      return Icon(
        color: Theme.of(context).colorScheme.inversePrimary,
        Icons.reply_outlined,
        size: 28,
      );
    } else if (mentioned == true) {
      return Icon(
        color: Theme.of(context).colorScheme.inversePrimary,
        Icons.alternate_email,
        size: 28,
      );
    } else if (conversation.flags.sticky) {
      return Icon(
        Icons.push_pin_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 28,
      );
    } else {
      return const Icon(
        Icons.chat_outlined,
        size: 28,
      );
    }
  }
}
