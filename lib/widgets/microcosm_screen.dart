import 'package:flutter/material.dart';
import '../models/microcosm.dart';

class MicrocosmScreen extends StatefulWidget {
  final Microcosm microcosm;
  const MicrocosmScreen({
    super.key,
    required this.microcosm,
  });

  @override
  State<MicrocosmScreen> createState() => _MicrocosmScreenState();
}

class _MicrocosmScreenState extends State<MicrocosmScreen> {
  @override
  Widget build(BuildContext context) {
    final Widget? fab = widget.microcosm.flags.open
        ? FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Not implemented yet'),
                  duration: Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Icon(Icons.add_comment_rounded),
          )
        : null;

    return Scaffold(
      floatingActionButton: fab,
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.microcosm.resetChildren();
          setState(() {});
        },
        child: CustomScrollView(
          // cacheExtent: 400.0,
          slivers: <Widget>[
            SliverAppBar(floating: true, title: Text(widget.microcosm.title)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return widget.microcosm.childTile(index);
                },
                childCount: widget.microcosm.totalChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
