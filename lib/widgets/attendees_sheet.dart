import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/attendee.dart';
import '../models/attendees.dart';

class AttendeesSheet extends StatefulWidget {
  const AttendeesSheet({
    super.key,
    required this.attendees,
  });

  final Attendees attendees;

  @override
  State<AttendeesSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<AttendeesSheet> {
  @override
  Widget build(BuildContext context) => ListView.separated(
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Row(
              children: [
                SizedBox(width: 30.0),
                Expanded(child: Text("Who?")),
                Text("Attending?"),
              ],
            );
          } else {
            return _attendee(
              widget.attendees.getChild(index - 1),
            );
          }
        },
        padding: const EdgeInsets.all(8.0),
        itemCount: widget.attendees.totalChildren + 1,
        separatorBuilder: (context, index) => const SizedBox(
          height: 8.0,
        ),
      );

  Widget _attendee(Future<Attendee> futureAttendee) => FutureBuilder(
        future: futureAttendee,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final attendee = snapshot.data!;
            return Row(
              children: [
                CachedNetworkImage(
                  imageUrl: attendee.profile.avatar,
                  width: 22,
                  height: 22,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(child: Text(attendee.profile.profileName)),
                Text(
                  attendee.rsvp.name,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Container(width: 22.0, height: 22.0, color: Colors.grey),
              ],
            );
          }
        },
      );
}
