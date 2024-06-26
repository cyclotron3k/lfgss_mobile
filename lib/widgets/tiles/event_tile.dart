import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../screens/future_screen.dart';
import '../time_ago.dart';

class EventTile extends StatelessWidget {
  final Event event;
  final bool? overrideUnreadFlag;

  const EventTile({
    super.key,
    required this.event,
    this.overrideUnreadFlag,
  });

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Card(
      key: ValueKey(event.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureScreen(
                item: Event.getById(event.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (event.flags.sticky
              ? Icon(
                  Icons.push_pin_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                )
              : const Icon(
                  Icons.calendar_month,
                  size: 28,
                )),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overrideUnreadFlag ?? event.flags.unread)
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
                  unescape.convert(event.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (event.lastActivity != null) TimeAgo(event.lastActivity!),
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
                  event.totalChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
