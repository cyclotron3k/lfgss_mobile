import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../models/event.dart';
import '../../services/microcosm_client.dart';
import '../new_comment.dart';

class EventScreen extends StatefulWidget {
  final Event event;
  const EventScreen({super.key, required this.event});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  bool refreshDisabled = false;

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.event.resetChildren();
    } finally {
      setState(() => refreshDisabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int forwardItemCount =
        widget.event.totalChildren - widget.event.startPage * PAGE_SIZE;
    Key forwardListKey = UniqueKey();
    Widget forwardList = SliverList.builder(
      key: forwardListKey,
      itemBuilder: (BuildContext context, int index) {
        if (forwardItemCount == index) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: refreshDisabled ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: Text(refreshDisabled ? 'Refreshing...' : 'Refresh'),
            ),
          );
        }
        return widget.event.childTile(
          forwardItemCount + 1,
        );
      },
      itemCount:
          widget.event.totalChildren - widget.event.startPage * PAGE_SIZE,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) => widget.event.childTile(
        widget.event.startPage * PAGE_SIZE - index - 1,
      ),
      itemCount: widget.event.startPage * PAGE_SIZE,
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              center: forwardListKey,
              slivers: [
                SliverAppBar(
                  // TODO: https://github.com/flutter/flutter/issues/132841
                  floating: true,
                  title: Text(widget.event.title),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(children: [
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(widget.event.when),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(widget.event.whenEnd),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.map),
                                title: Text(widget.event.where),
                              ),
                            ]),
                          ),
                          const Expanded(
                            child: Placeholder(
                              fallbackHeight: 200.0,
                            ),
                          ),
                        ],
                      ),
                      widget.event.getAttendees(),
                    ],
                  ),
                ),
                reverseList,
                forwardList,
              ],
            ),
          ),
          if (widget.event.flags.open && MicrocosmClient().loggedIn)
            NewComment(
              itemId: widget.event.id,
              itemType: CommentableType.event,
              onPostSuccess: () async {
                await widget.event.resetChildren();
                setState(() {});
              },
            )
        ],
      ),
    );
  }
}
