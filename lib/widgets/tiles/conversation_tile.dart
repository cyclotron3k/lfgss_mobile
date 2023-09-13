import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';

import '../../models/conversation.dart';
import '../screens/future_conversation_screen.dart';

class ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final bool? overrideUnreadFlag;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.overrideUnreadFlag,
  });

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Card(
      key: ValueKey(widget.conversation.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureConversationScreen(
                conversation: Conversation.getById(widget.conversation.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (widget.conversation.flags.sticky
              ? Icon(
                  Icons.push_pin_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                )
              : const Icon(
                  Icons.chat_outlined,
                  size: 28,
                )),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.overrideUnreadFlag ?? widget.conversation.flags.unread)
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
                  unescape.convert(widget.conversation.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(DateFormat.yMMMd().format(widget.conversation.created)),
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
                  widget.conversation.totalChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
