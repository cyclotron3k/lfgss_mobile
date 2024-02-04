import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:lfgss_mobile/widgets/tiles/comment_html.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../models/reply_notifier.dart';
import '../../services/link_parser.dart';
import '../../services/settings.dart';
import '../profile_sheet.dart';
import '../swipeable.dart';
import '../time_ago.dart';

class SingleComment extends StatefulWidget {
  final Comment comment;
  final bool highlight;
  const SingleComment(
      {super.key, required this.comment, this.highlight = false});

  @override
  State<SingleComment> createState() => _SingleCommentState();
}

class _SingleCommentState extends State<SingleComment> {
  late final bool _edited;
  late final bool _reply;
  late final bool _empty;
  late final bool _deleted;

  bool _replyActivated = false;
  bool _swipingEnabled = false;

  @override
  void initState() {
    super.initState();

    _swipingEnabled = context.read<ReplyNotifier?>() != null;

    _edited = widget.comment.revisions > 1;
    _reply = widget.comment.links.containsKey("inReplyToAuthor");
    _empty = widget.comment.markdown == ".";
    _deleted = _empty && !widget.comment.hasAttachments();
  }

  @override
  Widget build(BuildContext context) => Swipeable(
        direction:
            _swipingEnabled ? SwipeDirection.startToEnd : SwipeDirection.none,
        swipeThresholds: const {SwipeDirection.startToEnd: 0.18},
        background: Container(
          alignment: Alignment.centerLeft,
          // color: Colors.green,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: AnimatedSize(
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              child: Icon(
                Icons.reply,
                size: _replyActivated ? 32.0 : 22,
                color: _replyActivated ? Colors.green.shade300 : Colors.grey,
              ),
            ),
          ),
        ),
        onUpdate: (details) => setState(
          () => _replyActivated = details.reached,
        ),
        onRelease: (details) {
          setState(() {
            if (details.reached) {
              Provider.of<ReplyNotifier?>(
                context,
                listen: false,
              )?.setReplyTarget(
                widget.comment,
              );
            }
          });
        },
        key: ObjectKey(widget.comment),
        child: _body(context),
      );

  Widget _body(BuildContext context) {
    return Stack(
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
        Column(
          // key: ValueKey(widget.comment.id),
          children: [
            _titleBar(context),
            _commentBody(),
            if (widget.comment.hasAttachments())
              widget.comment.getAttachments(context: context),
          ],
        ),
      ],
    );
  }

  Widget _commentBody() {
    if (_empty) {
      return const SizedBox();
    }

    return Consumer<Settings>(
      builder: (context, settings, _) => CommentHtml(
        html: widget.comment.html,
        embedTweets: settings.getBool("embedTweets") ?? true,
        embedYouTube: settings.getBool("embedYouTube") ?? true,
        replyTarget: widget.comment,
      ),
    );
  }

  Widget _titleBar(BuildContext context) => Row(children: [
        Container(
          width: 38.0,
          padding: const EdgeInsets.all(8.0),
          child: CachedNetworkImage(
            imageUrl: widget.comment.createdBy.avatar,
            width: 22,
            height: 22,
            errorWidget: (context, url, error) => const Icon(
              Icons.person_outline,
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
                        ? Colors.grey
                        : Theme.of(context).textTheme.bodyMedium!.color),
                  ),
                ),
              ),
              if (_reply)
                InkWell(
                  onTap: () async {
                    LinkParser.parseUri(
                      context,
                      widget.comment.links["inReplyTo"]!.href,
                    );
                  },
                  child: Text(
                    "replied to ${HtmlUnescape().convert(widget.comment.links["inReplyToAuthor"]!.title ?? "")}",
                    style: const TextStyle(color: Colors.grey),
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
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              TimeAgo(widget.comment.created, color: Colors.grey),
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
