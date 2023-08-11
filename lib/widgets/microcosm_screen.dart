import 'package:flutter/material.dart';
import '../models/microcosm.dart';

class MicrocosmScreen extends StatelessWidget {
  const MicrocosmScreen({
    super.key,
    required this.microcosm,
  });

  final Microcosm microcosm;

  @override
  Widget build(BuildContext context) {
    final Widget? fab = microcosm.flags.open
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
          // TODO
          return Future.delayed(
            const Duration(milliseconds: 1000),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Not implemented yet'),
                  duration: Duration(milliseconds: 1500),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        },
        child: CustomScrollView(
          // cacheExtent: 400.0,
          slivers: <Widget>[
            SliverAppBar(floating: true, title: Text(microcosm.title)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return microcosm.childTile(index);
                },
                childCount: microcosm.totalChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
