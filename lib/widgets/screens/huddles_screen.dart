import 'package:flutter/material.dart';

import '../../models/huddles.dart';
import '../../models/search_parameters.dart';
import '../../services/microcosm_client.dart';
import '../../services/observer_utils.dart';
import '../adaptable_form.dart';
import 'search_screen.dart';

class HuddlesScreen extends StatefulWidget {
  final Huddles huddles;
  final ScrollController? controller;
  const HuddlesScreen({
    super.key,
    required this.huddles,
    this.controller,
  });

  @override
  State<HuddlesScreen> createState() => _HuddlesScreenState();
}

class _HuddlesScreenState extends State<HuddlesScreen> with RouteAware {
  final _spinnerKey = GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ObserverUtils.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    ObserverUtils.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() async => _spinnerKey.currentState?.show();

  Future<void> _refreshScreen() async {
    await widget.huddles.resetChildren();
    if (context.mounted) setState(() {});
  }

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
        key: _spinnerKey,
        onRefresh: _refreshScreen,
        child: CustomScrollView(
          // cacheExtent: 400.0,
          controller: widget.controller,
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
