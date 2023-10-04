import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lfgss_mobile/models/search.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../models/conversation.dart';
import '../../models/reply_notifier.dart';
import '../../models/search_parameters.dart';
import '../../services/microcosm_client.dart';
import '../new_comment.dart';
import 'future_conversation_screen.dart';
import 'future_search_screen.dart';

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;
  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  bool refreshDisabled = false;
  final TextEditingController _pageNoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late int maxPageNumber;

  @override
  void initState() {
    super.initState();
    maxPageNumber = (widget.conversation.totalChildren / 25).ceil();
  }

  Future<void> _refresh() async {
    setState(() => refreshDisabled = true);
    try {
      await widget.conversation.resetChildren();
    } finally {
      setState(() => refreshDisabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int forwardItemCount = widget.conversation.totalChildren -
        widget.conversation.startPage * PAGE_SIZE;
    Key forwardListKey = UniqueKey();
    Widget forwardList = SliverList.builder(
      key: forwardListKey,
      itemBuilder: (BuildContext context, int index) {
        if (forwardItemCount == index) {
          return Column(
            children: [
              const Divider(),
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
        return widget.conversation.childTile(
          widget.conversation.startPage * PAGE_SIZE + index,
        );
      },
      itemCount: forwardItemCount + 1,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) =>
          widget.conversation.childTile(
        widget.conversation.startPage * PAGE_SIZE - index - 1,
      ),
      itemCount: widget.conversation.startPage * PAGE_SIZE,
    );

    return Scaffold(
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          MenuAnchor(
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
                        builder: (context) => FutureSearchScreen(
                          search: Search.search(
                            searchParameters: SearchParameters(
                              query: "$query id:${widget.conversation.id}",
                              type: {'conversation', 'comment'},
                              sort: 'date',
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
                leadingIcon: const Icon(Icons.search),
                child: const Text('Find in conversation'),
              ),
              MenuItemButton(
                onPressed: () => Share.shareUri(widget.conversation.selfUrl),
                leadingIcon: Icon(Icons.adaptive.share),
                child: const Text('Share'),
              ),
              MenuItemButton(
                onPressed: _toggleSubscription,
                leadingIcon: Icon(widget.conversation.flags.watched
                    ? Icons.notifications_on
                    : Icons.notification_add_outlined),
                child: Text(widget.conversation.flags.watched
                    ? "Unfollow conversation"
                    : "Follow conversation"),
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
                        builder: (context) => FutureConversationScreen(
                          conversation: Conversation.getByPageNo(
                            widget.conversation.id,
                            pageNo,
                          ),
                        ),
                      ),
                    );
                  }
                },
                leadingIcon: const Icon(Icons.numbers),
                child: const Text('Jump to page'),
              ),
              MenuItemButton(
                onPressed: () => launchUrl(
                  widget.conversation.selfUrl,
                  mode: LaunchMode.externalApplication,
                ),
                leadingIcon: const Icon(Icons.open_in_browser),
                child: const Text('Open in browser'),
              ),
            ],
          ),
        ],
        title: Text(widget.conversation.title),
      ),
      body: ChangeNotifierProvider<ReplyNotifier>(
        create: (BuildContext context) => ReplyNotifier(),
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                center: forwardListKey,
                slivers: [
                  reverseList,
                  forwardList,
                ],
              ),
            ),
            if (widget.conversation.flags.open && MicrocosmClient().loggedIn)
              NewComment(
                itemId: widget.conversation.id,
                itemType: CommentableType.conversation,
                onPostSuccess: () async {
                  await widget.conversation.resetChildren();
                  if (context.mounted) setState(() {});
                },
              )
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSubscription() async {
    var result = widget.conversation.flags.watched
        ? await widget.conversation.unsubscribe()
        : await widget.conversation.subscribe();

    if (!context.mounted) return;
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
