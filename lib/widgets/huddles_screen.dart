import 'package:flutter/material.dart';
import '../models/huddles.dart';

class HuddlesScreen extends StatelessWidget {
  const HuddlesScreen({
    super.key,
    required this.huddles,
  });

  final Huddles huddles;

  @override
  Widget build(BuildContext context) {
    final Widget fab = FloatingActionButton(
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
    );

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
            const SliverAppBar(floating: true, title: Text("Huddles")),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return huddles.childTile(index);
                },
                childCount: huddles.totalChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
