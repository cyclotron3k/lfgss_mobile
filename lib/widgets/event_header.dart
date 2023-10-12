import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventHeader extends StatelessWidget {
  const EventHeader({
    super.key,
    required this.event,
  });

  final Event event;

  List<Widget> _timeBlock(BuildContext context) {
    if (event.when == null) {
      return [
        const ListTile(
          leading: Icon(Icons.timer_outlined),
          title: Text("TBD"),
        )
      ];
    }
    if (event.multiDay == true) {
      return [
        ListTile(
          leading: const Icon(Icons.play_arrow_outlined),
          title: Text(
            DateFormat('EEE d MMM, y h:mm a').format(event.start!),
          ),
          subtitle: _tzWarning(context),
        ),
        ListTile(
          leading: const Icon(Icons.stop_outlined),
          title: Text(
            DateFormat('EEE d MMM, y h:mm a').format(event.end!),
          ),
        ),
      ];
    }

    if (event.multiDay == false) {
      return [
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: Text(
            DateFormat('EEE d MMM, y').format(event.start!),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.watch_later_outlined),
          title: Text(
            "From ${DateFormat.jm().format(event.start!)} to ${DateFormat.jm().format(event.end!)}",
          ),
          subtitle: _tzWarning(context),
        ),
      ];
    }

    return [];
  }

  Widget? _tzWarning(BuildContext context) {
    if (event.equivalentTz() == false) {
      return Text(
        "⚠️ This event is in a different timezone",
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._timeBlock(context),
        ListTile(
          leading: const Icon(Icons.location_on),
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
        event.getAttendees(),
      ],
    );
  }
}
