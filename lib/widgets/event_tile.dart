import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import 'future_event_screen.dart';

class EventTile extends StatefulWidget {
  final Event event;
  final bool? overrideUnreadFlag;

  const EventTile({
    super.key,
    required this.event,
    this.overrideUnreadFlag,
  });

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> {
  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();

    return Card(
      key: ValueKey(widget.event.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureEventScreen(
                event: Event.getById(widget.event.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (widget.event.flags.sticky
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
              if (widget.overrideUnreadFlag ?? widget.event.flags.unread)
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
                  unescape.convert(widget.event.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(DateFormat.yMMMd().format(widget.event.created)),
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
                  widget.event.totalChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
