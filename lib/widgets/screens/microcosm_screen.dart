import 'package:flutter/material.dart';

import '../../models/microcosm.dart';
import '../../services/microcosm_client.dart';
import '../../services/observer_utils.dart';
import '../adaptable_form.dart';
import 'search_screen.dart';

class MicrocosmScreen extends StatefulWidget {
  final Microcosm microcosm;
  const MicrocosmScreen({
    super.key,
    required this.microcosm,
  });

  @override
  State<MicrocosmScreen> createState() => _MicrocosmScreenState();
}

class _MicrocosmScreenState extends State<MicrocosmScreen> with RouteAware {
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
    await widget.microcosm.resetChildren();
    if (context.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Widget? fab =
        widget.microcosm.flags.open && MicrocosmClient().loggedIn
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      maintainState: true,
                      builder: (context) => AdaptableForm(
                        onPostSuccess: () {},
                        defaultOperationType: OperationType.newConversation,
                        initialMicrocosm: widget.microcosm,
                        lock: true,
                      ),
                    ),
                  );
                  // if (!context.mounted) return;
                  // Navigator.pop(context);
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
          slivers: <Widget>[
            SliverAppBar(
              floating: true,
              title: Text(
                widget.microcosm.title,
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      maintainState: true,
                      builder: (context) => const SearchScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.search),
                )
              ],
            ),
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
