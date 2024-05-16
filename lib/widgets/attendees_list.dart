import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/event_attendees.dart';

import 'attendee_shimmer.dart';
import 'attendees_sheet.dart';

class AttendeesList extends StatelessWidget {
  final Future<EventAttendees> futureAttendees;
  final int initialAttendeeCount;
  final int rsvpAttend;
  final int preview = 8;

  const AttendeesList({
    super.key,
    required this.futureAttendees,
    required this.initialAttendeeCount,
    required this.rsvpAttend,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<EventAttendees>(
        future: futureAttendees,
        builder: (context, snapshot) {
          List<Widget> chips;
          if (snapshot.hasData) {
            final attendees = snapshot.data!;
            chips = List.generate(
              min(rsvpAttend, preview),
              (index) => attendees.childTile(index),
            );
            if (rsvpAttend > preview) {
              chips.add(
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text("+ ${rsvpAttend - preview} more"),
                  onPressed: () => _showProfileModal(context, attendees),
                ),
              );
            }
          } else {
            chips = List.generate(
              min(rsvpAttend, preview),
              (index) => const AttendeeShimmer(),
            );
            if (rsvpAttend > preview) {
              chips.add(
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text("+ ${rsvpAttend - preview} more"),
                ),
              );
            }
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Attendees ($rsvpAttend)"),
            ),
            Wrap(
              spacing: 8.0, // gap between adjacent chips
              runSpacing: 4.0, //
              children: chips,
            ),
          ]);
        },
      );

  Future<void> _showProfileModal(
    BuildContext context,
    EventAttendees attendees,
  ) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => AttendeesSheet(
          attendees: attendees,
        ),
      );
}
