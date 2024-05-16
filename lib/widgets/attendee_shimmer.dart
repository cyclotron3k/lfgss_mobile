import 'package:flutter/material.dart';

class AttendeeShimmer extends StatelessWidget {
  const AttendeeShimmer({super.key});

  @override
  Widget build(BuildContext context) => Chip(
        visualDensity: VisualDensity.compact,
        avatar: CircleAvatar(
          backgroundColor: Colors.grey.shade800,
        ),
        label: const SizedBox(width: 64.0),
      );
}
