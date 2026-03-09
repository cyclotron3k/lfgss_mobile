import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../core/commentable_item.dart';
import '../../models/comment_shuttle.dart';
import '../../models/event.dart';
import '../../models/huddle.dart';
import '../../models/refresh_request_notifier.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../services/microcosm_client.dart';
import '../event_header.dart';
import '../huddle_header.dart';
import '../new_comment.dart';
import 'commentable_item/comment_thread_slivers.dart';
import 'commentable_item/commentable_item_dialogs.dart';
import 'commentable_item/commentable_item_overflow_menu.dart';
import 'commentable_item/commentable_item_positioning.dart';
import 'commentable_item/floating_comment_header.dart';
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
  late final FloatingCommentHeaderController _floatingHeaderController;

  @override
  void initState() {
    super.initState();
    maxPageNumber = (widget.item.totalChildren / 25).ceil();
    _floatingHeaderController = FloatingCommentHeaderController(
      scrollController: _scrollController,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _floatingHeaderController.updateForContext(context);
  }

  @override
  void dispose() {
    _floatingHeaderController.dispose();
    _scrollController.dispose();
    _pageNoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasCustomHeader {
    return widget.item is Event || widget.item is Huddle;
  }

  String get _itemTypeLabel => widget.item.runtimeType.toString();

  Widget _buildHeader() {
    if (widget.item is Event) {
      return EventHeader(event: widget.item as Event);
    }
    if (widget.item is Huddle) {
      return HuddleHeader(huddle: widget.item as Huddle);
    }
    throw Exception(
      "Tried to create a header element for a ${widget.item.runtimeType} which doesn't have a handler defined.",
    );
  }

  GlobalKey _commentKey(int index) {
    return commentKeyForIndex(_commentKeys, index);
  }

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.item.resetChildren();
    } finally {
      if (mounted) {
        setState(() => refreshDisabled = false);
      }
    }
  }

  Future<void> _openSearch() async {
    final query = await showThreadSearchDialog(
      context: context,
      controller: _searchController,
    );

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
                query: '$query id:${widget.item.id}',
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
  }

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(uri: widget.item.selfUrl));
  }

  Future<void> _jumpToPage() async {
    final ret = await showPageJumpDialog(
      context: context,
      controller: _pageNoController,
      maxPageNumber: maxPageNumber,
    );

    if (ret != null) {
      final pageNo = int.parse(ret);
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
  }

  Future<void> _openInBrowser() async {
    final url = await webUrlForCurrentPosition(
      context: context,
      item: widget.item,
      commentKeys: _commentKeys,
    );
    if (!context.mounted) return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleSubscription() async {
    final result = widget.item.flags.watched
        ? await widget.item.unsubscribe()
        : await widget.item.subscribe();

    if (!mounted) return;
    setState(() {});

    final message = result
        ? 'Successfully updated subscription'
        : 'Failed to update subscription';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: TOAST_DURATION,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forwardItemCount =
        widget.item.totalChildren - widget.item.startPage * PAGE_SIZE;

    final reverseList = CommentThreadSliver(
      item: widget.item,
      startIndex: widget.item.startPage * PAGE_SIZE - 1,
      itemCount: widget.item.startPage * PAGE_SIZE,
      descending: true,
      onRefresh: _refresh,
      commentKeyForIndex: _commentKey,
    );

    final forwardList = CommentThreadSliver(
      key: _forwardListKey,
      item: widget.item,
      startIndex: widget.item.startPage * PAGE_SIZE,
      itemCount: forwardItemCount,
      appendRefreshAtEnd: true,
      refreshDisabled: refreshDisabled,
      onRefresh: _refresh,
      commentKeyForIndex: _commentKey,
    );

    final overflowMenu = CommentableItemOverflowMenu(
      itemTypeLabel: _itemTypeLabel,
      watched: widget.item.flags.watched,
      onSearch: _openSearch,
      onShare: _share,
      onToggleSubscription: _toggleSubscription,
      onJumpToPage: _jumpToPage,
      onOpenInBrowser: _openInBrowser,
    );

    return Scaffold(
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CommentShuttle()),
          ChangeNotifierProvider(create: (context) => RefreshRequestNotifier()),
        ],
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    center: _forwardListKey,
                    slivers: [
                      if (_hasCustomHeader)
                        SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),
                      reverseList,
                      forwardList,
                    ],
                  ),
                  FloatingCommentHeader(
                    title: widget.item.title,
                    action: overflowMenu,
                    translateY: _floatingHeaderController.translateY,
                    headerHeight: _floatingHeaderController.headerHeight,
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
                  if (context.mounted) {
                    setState(() {});
                  }
                },
              )
          ],
        ),
      ),
    );
  }
}
