import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:lfgss_mobile/models/comment.dart';

import '../core/commentable_item.dart';
import '../models/profile.dart';
import 'profile_sheet.dart';
import 'thread_view.dart';
import 'time_ago.dart';

class CommentHeader extends StatefulWidget {
  final Comment comment;
  final CommentableItem contextItem;
  final bool editable;
  final bool isEdited;
  final bool isDeleted;
  final bool inert;

  const CommentHeader({
    super.key,
    required this.comment,
    required this.contextItem,
    this.editable = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.inert = false,
  });

  Profile get createdBy => comment.createdBy;
  String get profileName => createdBy.profileName;
  DateTime get created => comment.created;
  String? get replyToProfile => comment.links["inReplyToAuthor"]?.title;

  @override
  State<CommentHeader> createState() => _CommentHeaderState();
}

class _CommentHeaderState extends State<CommentHeader> {
  final GlobalKey _singleLineKey = GlobalKey();
  bool _shouldWrap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfShouldWrap();
    });
  }

  @override
  void didUpdateWidget(CommentHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment ||
        oldWidget.editable != widget.editable ||
        oldWidget.isEdited != widget.isEdited ||
        oldWidget.isDeleted != widget.isDeleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfShouldWrap());
    }
  }

  void _checkIfShouldWrap() {
    final RenderBox? renderBox =
        _singleLineKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final parentWidth =
          MediaQuery.of(context).size.width - 32; // Assuming some padding

      setState(() {
        _shouldWrap = size.width > parentWidth;
      });
    }
  }

  Widget _buildSingleLineLayout() {
    return Visibility(
      visible: !_shouldWrap,
      maintainSize: !_shouldWrap,
      maintainAnimation: !_shouldWrap,
      maintainState: true,
      child: IntrinsicWidth(
        key: _singleLineKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => _showProfileModal(context),
              child: Container(
                width: 30.0,
                padding:
                    const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
                child: CachedNetworkImage(
                  imageUrl: widget.createdBy.avatar,
                  width: 22,
                  height: 22,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person_outline,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showProfileModal(context),
                    child: Text(
                      widget.createdBy.profileName,
                      style: TextStyle(
                        color: (widget.isDeleted
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).textTheme.bodyMedium!.color),
                      ),
                    ),
                  ),
                  if (widget.replyToProfile != null && !widget.inert)
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
                        "replied to ${HtmlUnescape().convert(widget.replyToProfile ?? "")}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isDeleted)
                  Text(
                    "Deleted •",
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (widget.isEdited)
                  Text(
                    "Edited •",
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                TimeAgo(
                  widget.created,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrappedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _showProfileModal(context),
                        child: Container(
                          width: 30.0,
                          padding:
                              const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
                          child: CachedNetworkImage(
                            imageUrl: widget.createdBy.avatar,
                            width: 22,
                            height: 22,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person_outline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.profileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (widget.replyToProfile != null)
                    Row(
                      children: [
                        const Text('replied to '),
                        Flexible(
                          child: Text(
                            widget.replyToProfile!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TimeAgo(
                  widget.created,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                if (widget.isEdited) const Text('Edited'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showProfileModal(BuildContext context) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => ProfileSheet(
          profile: widget.createdBy,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Opacity(
              opacity: _shouldWrap ? 0.0 : 1.0,
              child: _buildSingleLineLayout(),
            ),
            if (_shouldWrap) _buildWrappedLayout(),
          ],
        );
      },
    );
  }
}
