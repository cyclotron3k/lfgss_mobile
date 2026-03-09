import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../core/commentable_item.dart';
import '../../models/event.dart';
import '../../models/huddle.dart';
import '../../models/comment_shuttle.dart';
import '../../models/refresh_request_notifier.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../services/microcosm_client.dart';
import '../event_header.dart';
import '../huddle_header.dart';
import '../new_comment.dart';
import 'future_screen.dart';
import 'future_search_results_screen.dart';

class CommentableItemScreen extends StatefulWidget {
  final CommentableItem item;

  const CommentableItemScreen({super.key, required this.item});

  @override
  State<CommentableItemScreen> createState() => _CommentableItemScreenState();
}

class _CommentableItemScreenState extends State<CommentableItemScreen> {
  bool refreshDisabled = false;
  final TextEditingController _pageNoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _commentKeys = {};
  static const Key _forwardListKey = ValueKey<String>('forward-list-center');
  late int maxPageNumber;
  late final ValueNotifier<double> _floatingHeaderTranslateY;
  double _floatingHeaderHeight = kToolbarHeight;
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    maxPageNumber = (widget.item.totalChildren / 25).ceil();
    _floatingHeaderTranslateY = ValueNotifier<double>(-_floatingHeaderHeight);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextHeaderHeight = MediaQuery.paddingOf(context).top + kToolbarHeight;
    if ((nextHeaderHeight - _floatingHeaderHeight).abs() > 0.1) {
      final wasHidden =
          _floatingHeaderTranslateY.value <= -_floatingHeaderHeight + 0.5;
      _floatingHeaderHeight = nextHeaderHeight;
      final nextTranslateY =
          wasHidden ? -_floatingHeaderHeight : _floatingHeaderTranslateY.value;
      _floatingHeaderTranslateY.value =
          nextTranslateY.clamp(-_floatingHeaderHeight, 0.0);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _floatingHeaderTranslateY.dispose();
    _pageNoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    if (delta.abs() < 1.0) return;

    final nextTranslateY = (_floatingHeaderTranslateY.value - delta)
        .clamp(-_floatingHeaderHeight, 0.0);
    if ((nextTranslateY - _floatingHeaderTranslateY.value).abs() > 0.1) {
      _floatingHeaderTranslateY.value = nextTranslateY;
    }
  }

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.item.resetChildren();
    } finally {
      setState(() => refreshDisabled = false);
    }
  }

  bool get hasCustomHeader {
    return widget.item is Event || widget.item is Huddle;
  }

  Widget buildHeader() {
    if (widget.item is Event) {
      return EventHeader(event: widget.item as Event);
    } else if (widget.item is Huddle) {
      return HuddleHeader(huddle: widget.item as Huddle);
    }
    throw Exception(
      "Tried to create a header element for a ${widget.item.runtimeType} which doesn't have a handler defined.",
    );
  }

  Widget _pageDivider(int index) {
    if (index % 25 == 0) {
      return Row(
        children: [
          const Expanded(child: Divider(endIndent: 8.0)),
          Text(
            "Page ${index ~/ 25 + 1} of ${(widget.item.totalChildren - 1) ~/ 25 + 1}", // TODO fix
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).dividerColor,
            ),
          ),
          const Expanded(
              child: Divider(
            indent: 8.0,
          )),
        ],
      );
    } else {
      return const Divider();
    }
  }

  GlobalKey _commentKey(int index) {
    return _commentKeys.putIfAbsent(
      index,
      () => GlobalKey(debugLabel: 'comment-$index'),
    );
  }

  int? _currentCommentIndex() {
    if (!mounted) return null;

    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top + kToolbarHeight;
    final bottomInset = mediaQuery.padding.bottom;
    final viewportHeight = mediaQuery.size.height - topInset - bottomInset;

    if (viewportHeight <= 0) return null;

    final viewportCenterY = topInset + (viewportHeight / 2);
    int? bestIndex;
    double bestDistance = double.infinity;

    for (final entry in _commentKeys.entries) {
      final currentContext = entry.value.currentContext;
      if (currentContext == null) continue;

      final renderObject = currentContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final topLeft = renderObject.localToGlobal(Offset.zero);
      final rect = topLeft & renderObject.size;
      final isVisible =
          rect.bottom > topInset && rect.top < topInset + viewportHeight;
      if (!isVisible) continue;

      final distance = (rect.center.dy - viewportCenterY).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = entry.key;
      }
    }

    return bestIndex;
  }

  Future<Uri> _webUrlForCurrentPosition() async {
    final selfUrl = widget.item.selfUrl;
    final pathWithoutNewest = selfUrl.path.replaceFirst(
      RegExp(r'/newest/?$'),
      '',
    );
    final basePath = pathWithoutNewest.endsWith('/')
        ? pathWithoutNewest
        : '$pathWithoutNewest/';

    final visibleIndex = _currentCommentIndex();
    final fallbackOffset = ((widget.item.startPage * PAGE_SIZE) ~/ 25) * 25;
    final offset =
        visibleIndex == null ? fallbackOffset : (visibleIndex ~/ 25) * 25;

    int? visibleCommentId;
    if (visibleIndex != null) {
      try {
        visibleCommentId = await widget.item
            .getChild(visibleIndex)
            .then((comment) => comment.id)
            .timeout(
              const Duration(milliseconds: 150),
              onTimeout: () => null,
            );
      } catch (_) {
        visibleCommentId = null;
      }
    }

    return Uri(
      scheme: selfUrl.scheme,
      host: selfUrl.host,
      path: basePath,
      queryParameters: {'offset': offset.toString()},
      fragment: visibleCommentId == null ? null : 'comment$visibleCommentId',
    );
  }

  @override
  Widget build(BuildContext context) {
    int forwardItemCount =
        widget.item.totalChildren - widget.item.startPage * PAGE_SIZE;
    Widget forwardList = SliverList.builder(
      key: _forwardListKey,
      itemBuilder: (BuildContext context, int index) {
        if (forwardItemCount == index) {
          return Column(
            children: [
              _pageDivider(-1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: refreshDisabled ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(refreshDisabled ? 'Refreshing...' : 'Refresh'),
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _pageDivider(widget.item.startPage * PAGE_SIZE + index),
            KeyedSubtree(
              key: _commentKey(widget.item.startPage * PAGE_SIZE + index),
              child: widget.item.childTile(
                widget.item.startPage * PAGE_SIZE + index,
              ),
            ),
          ],
        );
      },
      itemCount: forwardItemCount + 1,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) => Column(
        children: [
          _pageDivider(widget.item.startPage * PAGE_SIZE - index - 1),
          KeyedSubtree(
            key: _commentKey(widget.item.startPage * PAGE_SIZE - index - 1),
            child: widget.item.childTile(
              widget.item.startPage * PAGE_SIZE - index - 1,
            ),
          ),
        ],
      ),
      itemCount: widget.item.startPage * PAGE_SIZE,
    );

    Widget overflowMenu = MenuAnchor(
      builder: (
        BuildContext context,
        MenuController controller,
        Widget? child,
      ) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
          tooltip: 'Show menu',
        );
      },
      menuChildren: <MenuItemButton>[
        MenuItemButton(
          onPressed: () async {
            String? query = await _showSearchDialog(context);

            if (query != null) {
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  maintainState: true,
                  builder: (context) => FutureSearchResultsScreen(
                    search: Search.search(
                      searchParameters: SearchParameters(
                        query: "$query id:${widget.item.id}",
                        type: {
                          SearchType.values.byName(
                            widget.item.runtimeType.toString().toLowerCase(),
                          ),
                          SearchType.comment,
                        },
                        sort: 'date',
                      ),
                    ),
                  ),
                ),
              );
            }
          },
          leadingIcon: const Icon(Icons.search),
          child: Text("Find in ${widget.item.runtimeType}"),
        ),
        MenuItemButton(
          onPressed: () =>
              SharePlus.instance.share(ShareParams(uri: widget.item.selfUrl)),
          leadingIcon: Icon(Icons.adaptive.share),
          child: const Text('Share'),
        ),
        MenuItemButton(
          onPressed: _toggleSubscription,
          leadingIcon: Icon(widget.item.flags.watched
              ? Icons.notifications_on
              : Icons.notification_add_outlined),
          child: Text(widget.item.flags.watched
              ? "Unfollow ${widget.item.runtimeType}"
              : "Follow ${widget.item.runtimeType}"),
        ),
        MenuItemButton(
          onPressed: () async {
            String? ret = await _showPageJumpDialog(context);

            if (ret != null) {
              int pageNo = int.parse(ret);
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  maintainState: true,
                  builder: (context) => FutureScreen(
                    item: widget.item.getByPageNo(pageNo),
                  ),
                ),
              );
            }
          },
          leadingIcon: const Icon(Icons.numbers),
          child: const Text('Jump to page'),
        ),
        MenuItemButton(
          onPressed: () async {
            final url = await _webUrlForCurrentPosition();
            if (!context.mounted) return;
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          },
          leadingIcon: const Icon(Icons.open_in_browser),
          child: const Text('Open in browser'),
        ),
      ],
    );

    return Scaffold(
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CommentShuttle()),
          ChangeNotifierProvider(create: (context) => RefreshRequestNotifier()),
        ],
        child: ChangeNotifierProvider<CommentShuttle>(
          create: (BuildContext context) => CommentShuttle(),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      center: _forwardListKey,
                      slivers: [
                        if (hasCustomHeader)
                          SliverToBoxAdapter(
                            child: buildHeader(),
                          ),
                        reverseList,
                        forwardList,
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: ValueListenableBuilder<double>(
                        valueListenable: _floatingHeaderTranslateY,
                        child: RepaintBoundary(
                          child: SizedBox(
                            height: _floatingHeaderHeight,
                            child: AppBar(
                              primary: true,
                              leading: null,
                              automaticallyImplyLeading: false,
                              title: Text(widget.item.title),
                              actions: <Widget>[overflowMenu],
                            ),
                          ),
                        ),
                        builder: (context, translateY, child) {
                          final floatingHeaderVisible =
                              translateY > -_floatingHeaderHeight + 0.5;
                          return IgnorePointer(
                            ignoring: !floatingHeaderVisible,
                            child: Transform.translate(
                              offset: Offset(0, translateY),
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.item.canComment && MicrocosmClient().loggedIn)
                NewComment(
                  itemId: widget.item.id,
                  itemType: CommentableType.values.byName(
                    widget.item.runtimeType.toString().toLowerCase(),
                  ),
                  onPostSuccess: (int? id) async {
                    await widget.item.resetChildren(childId: id);
                    if (context.mounted) setState(() {});
                  },
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSubscription() async {
    var result = widget.item.flags.watched
        ? await widget.item.unsubscribe()
        : await widget.item.subscribe();

    if (!mounted) return;
    setState(() {});

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully updated subscription"),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update subscription"),
          duration: TOAST_DURATION,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _showPageJumpDialog(BuildContext context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Jump to page...'),
          content: Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _pageNoController,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final number = int.tryParse(value);
                    if (number != null) {
                      final text = number.clamp(1, maxPageNumber).toString();
                      final selection = TextSelection.collapsed(
                        offset: text.length,
                      );
                      _pageNoController.value = TextEditingValue(
                        text: text,
                        selection: selection,
                      );
                    }
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    counterText: "",
                    hintText: "Page number",
                  ),
                ),
              ),
              Text("/ $maxPageNumber")
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('GO'),
              onPressed: () {
                Navigator.pop<String?>(
                  context,
                  _pageNoController.text,
                );
              },
            ),
          ],
        ),
      );

  Future<String?> _showSearchDialog(BuildContext context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Search in thread'),
          content: SizedBox(
            width: 100,
            child: TextField(
              controller: _searchController,
              maxLength: 512,
              decoration: const InputDecoration(
                counterText: "",
                hintText: "Search for...",
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('GO'),
              onPressed: () {
                Navigator.pop<String?>(
                  context,
                  _searchController.text,
                );
              },
            ),
          ],
        ),
      );
}
