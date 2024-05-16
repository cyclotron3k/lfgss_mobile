import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/attendee.dart';
import 'profile_sheet.dart';

class AttendeeChip extends StatelessWidget {
  final Attendee attendee;
  const AttendeeChip({super.key, required this.attendee});

  @override
  Widget build(BuildContext context) => ActionChip(
        visualDensity: VisualDensity.compact,
        onPressed: () => showModalBottomSheet<void>(
          enableDrag: true,
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) => ProfileSheet(
            profile: attendee.profile,
          ),
        ),
        avatar: CircleAvatar(
          foregroundImage: CachedNetworkImageProvider(attendee.profile.avatar),
          backgroundColor: Colors.grey.shade800,
        ),
        label: Text(attendee.profile.profileName),
      );
}
