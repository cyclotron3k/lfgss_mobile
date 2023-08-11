import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';

import '../models/huddle.dart';
import 'future_huddle_screen.dart';

class HuddleTile extends StatefulWidget {
  final Huddle huddle;
  const HuddleTile({super.key, required this.huddle});

  @override
  State<HuddleTile> createState() => _HuddleTileState();
}

class _HuddleTileState extends State<HuddleTile> {
  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    return Card(
      key: ValueKey(widget.huddle.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureHuddleScreen(
                huddle: Huddle.getById(widget.huddle.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (widget.huddle.flags.sticky
              ? const Icon(
                  Icons.push_pin_outlined,
                  color: Colors.blue,
                  size: 28,
                )
              : const Icon(
                  Icons.chat_outlined,
                  size: 28,
                )),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.huddle.flags.unread)
                const Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 6.0, 6.0, 6.0),
                  child: Icon(Icons.circle, size: 10.0, color: Colors.blue),
                ),
              Expanded(
                child: Text(
                  unescape.convert(widget.huddle.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(DateFormat.yMMMd().format(widget.huddle.created)),
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
                  widget.huddle.totalChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
