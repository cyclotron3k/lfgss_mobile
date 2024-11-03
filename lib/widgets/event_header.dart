import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:maps_launcher/maps_launcher.dart';

import '../models/attendee.dart';
import '../models/event.dart';
import '../models/user_provider.dart';
import '../widgets/attendees_list.dart';

class EventHeader extends StatefulWidget {
  const EventHeader({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<EventHeader> createState() => _EventHeaderState();
}

class _EventHeaderState extends State<EventHeader> {
  bool _updatingAttendance = false;

  List<Widget> _timeBlock(BuildContext context) {
    if (widget.event.when == null) {
      return [
        const ListTile(
          leading: Icon(Icons.timer_outlined),
          title: Text("TBD"),
        )
      ];
    }

    if (widget.event.multiDay == true) {
      return [
        ListTile(
          leading: const Icon(Icons.play_arrow_outlined),
          title: Text(
            DateFormat('EEE d MMM, y h:mm a').format(widget.event.start!),
          ),
          subtitle: _tzWarning(context),
        ),
        ListTile(
          leading: const Icon(Icons.stop_outlined),
          title: Text(
            DateFormat('EEE d MMM, y h:mm a').format(widget.event.end!),
          ),
          subtitle: _expiryWarning(),
        ),
      ];
    }

    if (widget.event.multiDay == false) {
      return [
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: Text(
            DateFormat('EEE d MMM, y').format(widget.event.start!),
          ),
          subtitle: _expiryWarning(),
        ),
        ListTile(
          leading: const Icon(Icons.watch_later_outlined),
          title: Text(
            "From ${DateFormat.jm().format(widget.event.start!)} to ${DateFormat.jm().format(widget.event.end!)}",
          ),
          subtitle: _tzWarning(context),
        ),
      ];
    }

    return [];
  }

  Widget _tzWarning(BuildContext context) =>
      widget.event.equivalentTz() == false
          ? Text(
              "⚠️ This event is in a different timezone",
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            )
          : const SizedBox.shrink();

  Widget _expiryWarning() => widget.event.timingStatus == EventTiming.expired
      ? const Text("This event has expired")
      : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ..._timeBlock(context),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: widget.event.where != null
                ? Text(widget.event.where!)
                : Text(
                    "TBD",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
            trailing: IconButton(
                onPressed: () {
                  if (widget.event.lat != null && widget.event.lon != null) {
                    MapsLauncher.launchCoordinates(
                      widget.event.lat!,
                      widget.event.lon!,
                      widget.event.where,
                    );
                  } else if (widget.event.where != null) {
                    MapsLauncher.launchQuery(
                      widget.event.where!,
                    );
                  }
                },
                icon: const Icon(Icons.map)),
          ),
          AttendeesList(
            futureAttendees: widget.event.getAttendees(),
            initialAttendeeCount: widget.event.rsvpAttend,
            rsvpAttend: widget.event.rsvpAttend,
          ),
          ..._attendanceButton(),
        ],
      );

  List<Widget> _attendanceButton() {
    int? userId = context.watch<UserProvider>().user?.id;
    bool hasUser = userId != null;

    if (hasUser && widget.event.timingStatus != EventTiming.expired) {
      if (_updatingAttendance) {
        return [
          ElevatedButton.icon(
            icon: const SizedBox(
              width: 18.0,
              height: 18.0,
              child: CircularProgressIndicator(),
            ),
            label: const Text("Loading"),
            onPressed: null,
          ),
        ];
      }
      if (widget.event.flags.attending) {
        return [
          ElevatedButton.icon(
            onPressed: () async {
              setState(() => _updatingAttendance = true);
              await widget.event.updateAttendance(
                userId,
                AttendeeStatus.no,
              );
              await widget.event.resetChildren();
              if (mounted) setState(() => _updatingAttendance = false);
            },
            icon: const Icon(Icons.close_outlined),
            label: const Text("Flounce"),
          ),
        ];
      } else {
        return [
          ElevatedButton.icon(
            onPressed: () async {
              setState(() => _updatingAttendance = true);
              await widget.event.updateAttendance(
                userId,
                AttendeeStatus.yes,
              );
              await widget.event.resetChildren();
              if (mounted) setState(() => _updatingAttendance = false);
            },
            icon: const Icon(Icons.add),
            label: const Text("Attend"),
          ),
        ];
      }
    } else {
      return [];
    }
  }
}
