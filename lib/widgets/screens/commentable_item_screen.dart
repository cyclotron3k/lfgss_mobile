import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../core/commentable_item.dart';
import '../../models/comment_shuttle.dart';
import '../../models/conversation.dart';
import '../../models/event.dart';
import '../../models/huddle.dart';
import '../../models/refresh_request_notifier.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../services/microcosm_client.dart';
import '../../services/settings.dart';
import '../event_header.dart';
import '../huddle_header.dart';
import '../new_comment.dart';
import 'commentable_item/comment_thread_slivers.dart';
import 'commentable_item/commentable_item_dialogs.dart';
import 'commentable_item/commentable_item_overflow_menu.dart';
import 'commentable_item/commentable_item_positioning.dart';
import 'commentable_item/floating_comment_header.dart';
import 'commentable_item/seek_bar.dart';
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
  bool _didAutoScrollToHighlight = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollHighlightedCommentIntoView();
    });
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

  int? get _highlightedCommentId {
    return switch (widget.item) {
      Conversation conversation =>
        conversation.highlight > 0 ? conversation.highlight : null,
      Event event => event.highlight > 0 ? event.highlight : null,
      Huddle huddle => huddle.highlight > 0 ? huddle.highlight : null,
      _ => null,
    };
  }

  Future<void> _scrollHighlightedCommentIntoView() async {
    if (_didAutoScrollToHighlight || !mounted) return;

    final highlightId = _highlightedCommentId;
    if (highlightId == null) return;

    final targetIndex = widget.item.getCachedCommentIndex(highlightId);
    if (targetIndex == null) return;

    _didAutoScrollToHighlight = true;

    const maxAttempts = 8;
    for (var attempt = 0; attempt < maxAttempts && mounted; attempt++) {
      final targetContext = _commentKeys[targetIndex]?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        final topPadding =
            MediaQuery.paddingOf(targetContext).top + kToolbarHeight;
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
        if (!mounted || !targetContext.mounted || !_scrollController.hasClients) {
          return;
        }

        final pos = _scrollController.position;
        _scrollController.jumpTo(
          (_scrollController.offset - topPadding).clamp(
            pos.minScrollExtent,
            pos.maxScrollExtent,
          ),
        );
        return;
      }

      if (!_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        continue;
      }
      if (!mounted) return;

      final visibleIndex = currentVisibleCommentIndex(
        context: context,
        commentKeys: _commentKeys,
      );
      final direction = (visibleIndex == null)
          ? (targetIndex >= widget.item.startPage * PAGE_SIZE ? 1.0 : -1.0)
          : (targetIndex > visibleIndex ? 1.0 : -1.0);

      final currentOffset = _scrollController.offset;
      final viewport = _scrollController.position.viewportDimension;
      final nextOffset = (currentOffset + (viewport * 0.85 * direction)).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      if ((nextOffset - currentOffset).abs() < 1.0) {
        return;
      }

      _scrollController.jumpTo(nextOffset);
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
  }

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
      if (!mounted) return;
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

  double _getSeekFraction() {
    final index = currentVisibleCommentIndex(
      context: context,
      commentKeys: _commentKeys,
    );
    if (index == null || widget.item.totalChildren <= 1) return 0.0;
    return (index / (widget.item.totalChildren - 1)).clamp(0.0, 1.0);
  }

  Future<void> _jumpToSpecificPage(int pageNo) async {
    if (pageNo == widget.item.startPage + 1) return;
    if (!context.mounted) return;
    await Navigator.pushReplacement(
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

  Future<void> _jumpToPage() async {
    final ret = await showPageJumpDialog(
      context: context,
      controller: _pageNoController,
      maxPageNumber: maxPageNumber,
    );

    if (ret != null) {
      await _jumpToSpecificPage(int.parse(ret));
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
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final seekBarSensitivity = SeekBarSensitivity.values.byName(
      Provider.of<Settings>(
            context,
            listen: false,
          ).getString("seekBarSensitivity") ??
          "low",
    );
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
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: topPadding,
                        ),
                      ),
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
                  SeekBar(
                    scrollController: _scrollController,
                    totalChildren: widget.item.totalChildren,
                    topPadding: topPadding,
                    sensitivity: seekBarSensitivity,
                    onSeek: _jumpToSpecificPage,
                    getFraction: _getSeekFraction,
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
