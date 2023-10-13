import 'package:flutter/material.dart';

import '../../models/huddles.dart';
import '../../models/search_parameters.dart';
import '../../services/microcosm_client.dart';
import '../adaptable_form.dart';
import 'search_screen.dart';

class HuddlesScreen extends StatefulWidget {
  final Huddles huddles;
  const HuddlesScreen({
    super.key,
    required this.huddles,
  });

  @override
  State<HuddlesScreen> createState() => _HuddlesScreenState();
}

class _HuddlesScreenState extends State<HuddlesScreen> {
  @override
  Widget build(BuildContext context) {
    final Widget? fab = MicrocosmClient().loggedIn
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  maintainState: true,
                  builder: (context) => AdaptableForm(
                    onPostSuccess: () {},
                    defaultOperationType: OperationType.newHuddle,
                    lock: true,
                  ),
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
          await widget.huddles.resetChildren();
          if (context.mounted) setState(() {});
        },
        child: CustomScrollView(
          // cacheExtent: 400.0,
          slivers: <Widget>[
            SliverAppBar(
              floating: true,
              title: const Text("Huddles"),
              actions: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      maintainState: true,
                      builder: (context) => SearchScreen(
                        initialQuery: SearchParameters(
                          query: "",
                          type: {SearchType.huddle, SearchType.comment},
                          inTitle: true,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.search),
                )
              ],
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return widget.huddles.childTile(index);
                },
                childCount: widget.huddles.totalChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
