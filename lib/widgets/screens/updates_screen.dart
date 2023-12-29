import 'package:flutter/material.dart';

import '../../models/search_parameters.dart';
import '../../models/updates.dart';
import '../../services/observer_utils.dart';
import 'search_screen.dart';

class UpdatesScreen extends StatefulWidget {
  final Updates updates;
  const UpdatesScreen({
    super.key,
    required this.updates,
  });

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> with RouteAware {
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
  void didPopNext() async {
    await _refreshScreen();
  }

  Future<void> _refreshScreen() async {
    await widget.updates.resetChildren();
    if (context.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshScreen,
      child: CustomScrollView(
        // cacheExtent: 400.0,
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            title: const Text("Updates"),
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
                        following: true,
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
                return widget.updates.childTile(index);
              },
              childCount: widget.updates.totalChildren,
            ),
          ),
        ],
      ),
    );
  }
}
