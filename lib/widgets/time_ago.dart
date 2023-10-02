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
      message: DateFormat.yMMMEd().add_Hms().format(widget.dateTime),
      child: Text(format(widget.dateTime),
          maxLines: 1,
          style: TextStyle(
            color: widget.color,
          )),
    );
  }
}
