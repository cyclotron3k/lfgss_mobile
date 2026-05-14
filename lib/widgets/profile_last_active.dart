import 'dart:async';

import 'package:flutter/material.dart';

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
  final localDateTime = dateTime.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();

  final localDay = DateTime(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
  );
  final today = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
  );
  final yesterday = today.subtract(const Duration(days: 1));
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final startOfMonth = DateTime(today.year, today.month);
  final startOfYear = DateTime(today.year);
  final startOfLastYear = DateTime(today.year - 1);

  if (!localDay.isBefore(today)) return "today";
  if (localDay == yesterday) return "yesterday";
  if (!localDay.isBefore(startOfWeek)) return "this week";
  if (!localDay.isBefore(startOfMonth)) return "this month";
  if (!localDay.isBefore(startOfYear)) return "this year";
  if (!localDay.isBefore(startOfLastYear)) return "last year";

  return "more than a year ago";
}
