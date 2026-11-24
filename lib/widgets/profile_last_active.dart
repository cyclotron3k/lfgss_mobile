import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileLastActive extends StatefulWidget {
  const ProfileLastActive(
    this.dateTime, {
    super.key,
    this.color,
  });

  final DateTime dateTime;
  final Color? color;

  @override
  State<ProfileLastActive> createState() => _ProfileLastActiveState();
}

class _ProfileLastActiveState extends State<ProfileLastActive> {
  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(hours: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = profileLastActiveLabel(
      widget.dateTime,
    );

    return Tooltip(
      message: label,
      child: Text(
        label,
        style: TextStyle(
          color: widget.color,
        ),
      ),
    );
  }
}

@visibleForTesting
String profileLastActiveLabel(
  DateTime dateTime, {
  DateTime? now,
}) {
  return DateFormat('MMMM y').format(dateTime.toLocal());
}
