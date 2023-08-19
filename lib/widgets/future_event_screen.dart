import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/event_screen.dart';

import '../models/event.dart';

class FutureEventScreen extends StatefulWidget {
  final Future<Event> event;
  const FutureEventScreen({super.key, required this.event});

  @override
  State<FutureEventScreen> createState() => _FutureEventScreenState();
}

class _FutureEventScreenState extends State<FutureEventScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event>(
      future: widget.event,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return EventScreen(event: snapshot.data!);
        } else if (snapshot.hasError) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64.0,
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
