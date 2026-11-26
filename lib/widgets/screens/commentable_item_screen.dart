import 'package:flutter/material.dart';
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
import '../event_header.dart';
import '../huddle_header.dart';
import '../new_comment.dart';
import 'commentable_item/commentable_item_dialogs.dart';
import 'commentable_item/commentable_item_overflow_menu.dart';
import 'commentable_item/commentable_item_positioning.dart';
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
  final ValueNotifier<int> _navigationRevision = ValueNotifier<int>(0);
  bool _isAtTop = true;
  bool _isAtBottom = false;
  late int maxPageNumber;
  int? _visibleCommentIndex;

  @override
  void initState() {
    super.initState();
    maxPageNumber = (widget.item.totalChildren / 25).ceil();
    _itemPositionsListener.itemPositions.addListener(
      _handleItemPositionsChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollHighlightedCommentIntoView();
    });
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleItemPositionsChanged,
    );
    _navigationRevision.dispose();
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

  int _commentIndexForItemIndex(int itemIndex) =>
      itemIndex - _threadListLeadingItems;

  int _itemIndexForCommentIndex(int commentIndex) =>
      _threadListLeadingItems + commentIndex;

  double get _preferredScrollAlignment =>
      _initialCommentIndex == 0 ? 0.0 : 0.12;

  void _handleItemPositionsChanged() {
    final visibleIndex = currentVisibleCommentIndex(
      itemPositions: _itemPositionsListener.itemPositions.value,
      commentListStartIndex: _threadListLeadingItems,
      totalChildren: widget.item.totalChildren,
    );
    if (_visibleCommentIndex == visibleIndex) return;

    _visibleCommentIndex = visibleIndex;
    _navigationRevision.value++;
  }

  void _scrollToCommentIndex(
    int commentIndex, {
    bool animate = false,
    double? alignment,
  }) {
    final targetIndex = _itemIndexForCommentIndex(commentIndex);
    if (!_itemScrollController.isAttached) return;

    if (animate) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: alignment ?? _preferredScrollAlignment,
      );
      return;
    }

    _itemScrollController.jumpTo(
      index: targetIndex,
      alignment: alignment ?? _preferredScrollAlignment,
    );
  }

  Future<void> _centerOnPage(int pageNo) async {
    final commentIndex = ((pageNo - 1) * 25).clamp(
      0,
      widget.item.totalChildren == 0 ? 0 : widget.item.totalChildren - 1,
    );
    _scrollToCommentIndex(commentIndex);
  }

  void _jumpToTop() {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.jumpTo(index: 0, alignment: 0.0);
  }

  void _jumpToBottom() {
    if (!_itemScrollController.isAttached || widget.item.totalChildren == 0) {
      return;
    }
    _itemScrollController.jumpTo(index: _threadItemCount - 1, alignment: 1.0);
  }

  void _moveOnePage(int direction) {
    final current = _visibleCommentIndex;
    if (current == null || widget.item.totalChildren == 0) return;
    final target = direction < 0
        ? ((current - 1) ~/ 25) * 25
        : ((current ~/ 25) + 1) * 25;
    if (target >= 0 && target < widget.item.totalChildren) {
      _scrollToCommentIndex(target);
    }
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
    _isAtTop =
        notification.metrics.pixels <=
        notification.metrics.minScrollExtent + 1.0;
    _isAtBottom =
        notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 1.0;
    _navigationRevision.value++;

    return false;
  }

  Widget _buildNavigationButtons() {
    return ValueListenableBuilder<int>(
      valueListenable: _navigationRevision,
      builder: (context, current, child) {
        final currentIndex = _visibleCommentIndex;
        final total = widget.item.totalChildren;
        final canPageUp = currentIndex != null && currentIndex >= 25;
        final canPageDown =
            currentIndex != null && ((currentIndex ~/ 25) + 1) * 25 < total;
        return Positioned(
          left: 8,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavigationButton(
                icon: Icons.first_page,
                enabled: !_isAtTop && total > 0,
                tooltip: 'Jump to top',
                onPressed: _jumpToTop,
              ),
              _NavigationButton(
                icon: Icons.navigate_before,
                enabled: canPageUp,
                tooltip: 'Go up one page',
                onPressed: () => _moveOnePage(-1),
              ),
              _NavigationButton(
                icon: Icons.navigate_next,
                enabled: canPageDown,
                tooltip: 'Go down one page',
                onPressed: () => _moveOnePage(1),
              ),
              _NavigationButton(
                icon: Icons.last_page,
                enabled: !_isAtBottom && total > 0,
                tooltip: 'Jump to bottom',
                onPressed: _jumpToBottom,
              ),
            ],
          ),
        );
      },
    );
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
        automaticallyImplyLeading: false,
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
                      initialScrollIndex: _itemIndexForCommentIndex(
                        _initialCommentIndex,
                      ),
                      initialAlignment: _preferredScrollAlignment,
                      itemBuilder: _buildThreadListItem,
                    ),
                  ),
                  _buildNavigationButtons(),
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
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  const _NavigationButton({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = enabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Icon(
                    icon,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
