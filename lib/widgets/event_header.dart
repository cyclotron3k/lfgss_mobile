import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventHeader extends StatelessWidget {
  const EventHeader({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    DateFormat.yMMMd().add_jm().format(event.when),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    DateFormat.yMMMd().add_jm().format(event.whenEnd),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: event.where != null
                      ? Text(event.where!)
                      : const Text(
                          "TBD",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ]),
            ),
            const Expanded(
              child: Placeholder(
                fallbackHeight: 200.0,
              ),
            ),
          ],
        ),
        event.getAttendees(),
      ],
    );
  }
}
