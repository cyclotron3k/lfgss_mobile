import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:provider/provider.dart';

import '../../core/commentable_item.dart';
import '../../models/comment.dart';
import '../../models/comment_shuttle.dart';
import '../../models/user_provider.dart';
import '../../services/settings.dart';
import '../profile_sheet.dart';
import '../swipeable.dart';
import '../thread_view.dart';
import '../time_ago.dart';
import 'comment_html.dart';

class SingleComment extends StatefulWidget {
  final Comment comment;
  final CommentableItem contextItem;
  final bool highlight;
  final bool inert;

  const SingleComment({
    super.key,
    required this.comment,
    required this.contextItem,
    this.highlight = false,
    this.inert = false,
  });

  @override
  State<SingleComment> createState() => _SingleCommentState();
}

class _SingleCommentState extends State<SingleComment> {
  late final bool _edited;
  late final bool _reply;
  late final bool _empty;
  late final bool _deleted;
  final _activatedNotifier = ValueNotifier<bool>(false);

  bool _swipingEnabled = false;

  @override
  void initState() {
    super.initState();

    _swipingEnabled = !widget.inert && context.read<CommentShuttle?>() != null;

    _edited = widget.comment.revisions > 1;
    _reply = widget.comment.links.containsKey("inReplyToAuthor");
    _empty = widget.comment.markdown == ".";
    _deleted = _empty && !widget.comment.hasAttachments;
  }

  @override
  void dispose() {
    _activatedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool owner = false;
    if (!widget.inert && Provider.of<UserProvider>(context).hasUser) {
      owner = widget.comment.createdBy.id ==
          Provider.of<UserProvider>(
            context,
            listen: false,
          ).user!.id;
    }

    return Swipeable(
      direction:
          _swipingEnabled ? SwipeDirection.startToEnd : SwipeDirection.none,
      swipeThresholds: const {SwipeDirection.startToEnd: 0.18},
      background: Container(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: AnimatedSize(
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            child: ValueListenableBuilder<bool>(
              valueListenable: _activatedNotifier,
              builder: (context, replyActivated, _) => Icon(
                Icons.reply,
                size: replyActivated ? 32.0 : 22,
                color: replyActivated ? Colors.green.shade300 : Colors.grey,
              ),
            ),
          ),
        ),
      ),
      onUpdate: (details) => _activatedNotifier.value = details.reached,
      onRelease: (details) {
        if (details.reached) {
          Provider.of<CommentShuttle?>(
            context,
            listen: false,
          )?.setReplyTarget(
            widget.comment,
          );
        }
      },
      key: ObjectKey(widget.comment),
      child: _body(context, owner),
    );
  }

  Widget _body(BuildContext context, bool owner) => Stack(
        children: [
          if (widget.highlight)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4.0),
                      bottomRight: Radius.circular(4.0),
                    ),
                    child: Container(
                      width: 4.0,
                      height: double.infinity,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Column(
              // key: ValueKey(widget.comment.id),
              children: [
                _titleBar(context, owner),
                _commentBody(owner),
                if (widget.comment.hasAttachments)
                  widget.comment.getAttachments(context: context),
              ],
            ),
          ),
        ],
      );

  Widget _commentBody(bool owner) {
    if (_empty) {
      return const SizedBox();
    }

    return Consumer<Settings>(
      builder: (context, settings, _) => CommentHtml(
        html: widget.comment.html,
        selectable: true,
        embedTweets: settings.getBool("embedTweets") ?? true,
        embedYouTube: settings.getBool("embedYouTube") ?? true,
        replyTarget: widget.comment,
      ),
    );
  }

  Widget _titleBar(BuildContext context, bool owner) => Row(children: [
        InkWell(
          onTap: () => _showProfileModal(context),
          child: Container(
            width: 30.0,
            padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
            child: CachedNetworkImage(
              imageUrl: widget.comment.createdBy.avatar,
              width: 22,
              height: 22,
              errorWidget: (context, url, error) => const Icon(
                Icons.person_outline,
              ),
            ),
          ),
        ),
        Expanded(
          flex: _reply ? 2 : 1,
          child: Wrap(
            spacing: 4.0,
            children: [
              InkWell(
                onTap: () => _showProfileModal(context),
                child: Text(
                  widget.comment.createdBy.profileName,
                  style: TextStyle(
                    color: (_deleted
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).textTheme.bodyMedium!.color),
                  ),
                ),
              ),
              if (_reply && !widget.inert)
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) => Dialog(
                      clipBehavior: Clip.hardEdge,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                          ),
                          child: ThreadView(
                            rootComment: widget.comment,
                            commentableItem: widget.contextItem,
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    "replied to ${HtmlUnescape().convert(widget.comment.links["inReplyToAuthor"]!.title ?? "")}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: _edited ? 2 : 1,
          child: Wrap(
            runAlignment: WrapAlignment.end,
            alignment: WrapAlignment.end,
            spacing: 4.0,
            children: [
              if (_edited)
                Text(
                  (_deleted ? "Deleted •" : "Edited •"),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              TimeAgo(
                widget.comment.created,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              if (owner && !widget.inert)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => Provider.of<CommentShuttle?>(
                        context,
                        listen: false,
                      )?.setEditTarget(
                        widget.comment,
                      ),
                      child: const Text("Edit"),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
      ]);

  Future<void> _showProfileModal(BuildContext context) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => ProfileSheet(
          profile: widget.comment.createdBy,
        ),
      );
}
