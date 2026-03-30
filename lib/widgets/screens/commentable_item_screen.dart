import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
import 'commentable_item/commentable_item_dialogs.dart';
import 'commentable_item/commentable_item_overflow_menu.dart';
import 'commentable_item/commentable_item_positioning.dart';
import 'commentable_item/seek_bar.dart';
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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isUserScrolling = ValueNotifier<bool>(false);
  final ValueNotifier<double> _seekFraction = ValueNotifier<double>(0.0);
  late int maxPageNumber;
  int? _visibleCommentIndex;

  @override
  void initState() {
    super.initState();
    maxPageNumber = (widget.item.totalChildren / 25).ceil();
    _itemPositionsListener.itemPositions
        .addListener(_handleItemPositionsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollHighlightedCommentIntoView();
    });
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleItemPositionsChanged,
    );
    _scrollOffset.dispose();
    _isUserScrolling.dispose();
    _seekFraction.dispose();
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
    _scrollToCommentIndex(targetIndex, animate: true);
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

  int get _threadListLeadingItems => _hasCustomHeader ? 1 : 0;

  int get _threadItemCount =>
      _threadListLeadingItems + widget.item.totalChildren + 1;

  int get _initialCommentIndex {
    final highlightedCommentId = _highlightedCommentId;
    final highlightedIndex = highlightedCommentId == null
        ? null
        : widget.item.getCachedCommentIndex(highlightedCommentId);
    return (highlightedIndex ?? widget.item.startPage * PAGE_SIZE).clamp(
      0,
      widget.item.totalChildren == 0 ? 0 : widget.item.totalChildren - 1,
    );
  }

  int _commentIndexForItemIndex(int itemIndex) {
    return itemIndex - _threadListLeadingItems;
  }

  int _itemIndexForCommentIndex(int commentIndex) {
    return _threadListLeadingItems + commentIndex;
  }

  void _handleItemPositionsChanged() {
    final visibleIndex = currentVisibleCommentIndex(
      itemPositions: _itemPositionsListener.itemPositions.value,
      commentListStartIndex: _threadListLeadingItems,
      totalChildren: widget.item.totalChildren,
    );
    if (_visibleCommentIndex == visibleIndex) return;

    _visibleCommentIndex = visibleIndex;
    _seekFraction.value = visibleIndex == null || widget.item.totalChildren <= 1
        ? 0.0
        : (visibleIndex / (widget.item.totalChildren - 1)).clamp(0.0, 1.0);
  }

  void _scrollToCommentIndex(int commentIndex, {bool animate = false}) {
    final targetIndex = _itemIndexForCommentIndex(commentIndex);
    if (!_itemScrollController.isAttached) return;

    if (animate) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
      return;
    }

    _itemScrollController.jumpTo(index: targetIndex, alignment: 0.12);
  }

  Future<void> _centerOnPage(int pageNo) async {
    final commentIndex = ((pageNo - 1) * 25).clamp(
      0,
      widget.item.totalChildren == 0 ? 0 : widget.item.totalChildren - 1,
    );
    _scrollToCommentIndex(commentIndex);
  }

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.item.resetChildren();
      _handleItemPositionsChanged();
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

  Future<void> _jumpToSpecificPage(int pageNo) async {
    _centerOnPage(pageNo);
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
    final visibleCommentId = _visibleCommentIndex == null
        ? null
        : await widget.item
            .getChild(_visibleCommentIndex!)
            .then<int?>((comment) => comment.id)
            .timeout(
              const Duration(milliseconds: 150),
              onTimeout: () => null,
            );
    final url = webUrlForCurrentPosition(
      item: widget.item,
      visibleIndex: _visibleCommentIndex,
      visibleCommentId: visibleCommentId,
    );
    if (!context.mounted) return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _scrollOffset.value = notification.metrics.pixels;

    if (notification is ScrollStartNotification) {
      _isUserScrolling.value = notification.dragDetails != null;
    } else if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        _isUserScrolling.value = true;
      }
    } else if (notification is UserScrollNotification) {
      _isUserScrolling.value = notification.direction != ScrollDirection.idle;
    } else if (notification is ScrollEndNotification) {
      _isUserScrolling.value = false;
    } else if (notification is OverscrollNotification) {
      if (notification.dragDetails != null) {
        _isUserScrolling.value = true;
      }
    }

    return false;
  }

  Widget _buildThreadListItem(BuildContext context, int index) {
    if (_hasCustomHeader && index == 0) {
      return _buildHeader();
    }

    final commentIndex = _commentIndexForItemIndex(index);
    if (commentIndex >= widget.item.totalChildren) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: refreshDisabled ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: Text(refreshDisabled ? 'Refreshing...' : 'Refresh'),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (commentIndex % 25 == 0)
          Row(
            children: [
              const Expanded(child: Divider(endIndent: 8.0)),
              Text(
                'Page ${commentIndex ~/ 25 + 1} of ${(widget.item.totalChildren - 1) ~/ 25 + 1}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).dividerColor,
                ),
              ),
              const Expanded(child: Divider(indent: 8.0)),
            ],
          )
        else
          const Divider(),
        widget.item.childTile(commentIndex),
      ],
    );
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
    final seekBarSensitivity = SeekBarSensitivity.values.byName(
      Provider.of<Settings>(
            context,
            listen: false,
          ).getString("seekBarSensitivity") ??
          "low",
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
      appBar: AppBar(
        title: Text(widget.item.title),
        actions: [overflowMenu],
      ),
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
                  NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: ScrollablePositionedList.builder(
                      itemCount: _threadItemCount,
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      initialScrollIndex:
                          _itemIndexForCommentIndex(_initialCommentIndex),
                      initialAlignment: 0.12,
                      itemBuilder: _buildThreadListItem,
                    ),
                  ),
                  SeekBar(
                    scrollOffsetListenable: _scrollOffset,
                    isUserScrollingListenable: _isUserScrolling,
                    fractionListenable: _seekFraction,
                    totalChildren: widget.item.totalChildren,
                    topPadding: 0.0,
                    sensitivity: seekBarSensitivity,
                    onSeek: _jumpToSpecificPage,
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
