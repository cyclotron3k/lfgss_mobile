import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventHeader extends StatelessWidget {
  const EventHeader({
    super.key,
    required this.event,
  });

  final Event event;

  List<Widget> _timeBlock() {
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
          subtitle: _tzWarning(),
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
          subtitle: _tzWarning(),
        ),
        ListTile(
          leading: const Icon(Icons.watch_later_outlined),
          title: Text(
            "From ${DateFormat.jm().format(event.start!)} to ${DateFormat.jm().format(event.end!)}",
          ),
        ),
      ];
    }

    return [];
  }

  Widget? _tzWarning() {
    return FutureBuilder<String>(
      future: FlutterTimezone.getLocalTimezone(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (event.equivalentTz(snapshot.data!) == false) {
            return Text(
              "This event is in a different timezone",
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._timeBlock(),
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
