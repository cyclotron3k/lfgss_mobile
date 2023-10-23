import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' show format;

class TimeAgo extends StatefulWidget {
  const TimeAgo(
    this.dateTime, {
    super.key,
    this.color,
  });

  final DateTime dateTime;
  final Color? color;

  @override
  State<TimeAgo> createState() => _TimeAgoState();
}

class _TimeAgoState extends State<TimeAgo> {
  late Timer timer;
  final String localTimeZone = Intl.getCurrentLocale();

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 10),
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
    return Tooltip(
      message: DateFormat.yMMMEd().add_jmz().format(
            widget.dateTime.toLocal(),
          ),
      child: Text(
        format(widget.dateTime),
        style: TextStyle(
          color: widget.color,
        ),
      ),
    );
  }
}
