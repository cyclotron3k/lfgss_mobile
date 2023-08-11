import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:developer' as developer;

import '../models/comment.dart';
import 'missing_image.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  const CommentTile({super.key, required this.comment});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      // key: ValueKey(widget.comment.id),
      children: [
        const Divider(),
        Row(
          children: [
            Padding(
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
              child: InkWell(
                onTap: () {
                  showModalBottomSheet<void>(
                    enableDrag: true,
                    showDragHandle: true,
                    context: context,
                    constraints: const BoxConstraints(
                      maxWidth: 380,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.0),
                      ),
                    ),
                    builder: (BuildContext context) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CachedNetworkImage(
                              imageUrl: widget.comment.createdBy.avatar,
                              width: 256,
                              height: 256,
                              errorWidget: (context, url, error) => const Icon(
                                Icons.person_outline,
                              ),
                            ),
                            Text(
                              widget.comment.createdBy.profileName,
                            ),
                            ElevatedButton(
                              child: const Text(
                                'Close',
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  widget.comment.createdBy.profileName,
                ),
              ),
            ),
            if (widget.comment.revisions > 1)
              Tooltip(
                message: "Edited",
                child: Icon(
                  Icons.edit_note_outlined,
                  color: Theme.of(context).hintColor,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat.yMMMd().format(widget.comment.created),
                ),
              ),
            ),
          ],
        ),
        Html(
          data: widget.comment.html,
          onLinkTap: (
            String? url,
            // RenderContext renderContext,
            Map<String, String> attributes,
            element,
          ) {
            //open URL in webview, or launch URL in browser, or any other logic here
            developer.log(
              url ?? "Link tapped, but no link exists",
            );
          },
          extensions: [
            ImageExtension(
              handleNetworkImages: true,
              handleAssetImages: false,
              handleDataImages: false,
              builder: (ExtensionContext ec) {
                return CachedNetworkImage(
                  imageUrl: ec.attributes["src"]!,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 32.0,
                        maxWidth: 32.0,
                      ),
                      child: CircularProgressIndicator(
                        value: downloadProgress.progress,
                        // color: Theme.of(context).highlightColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const SizedBox(
                    width: 64,
                    child: MissingImage(),
                  ),
                );
              },
            )
          ],
          style: {
            "img": Style(
              padding: HtmlPaddings.only(
                top: 10.0,
                bottom: 10.0,
              ),
            ),
            "blockquote": Style(
              padding: HtmlPaddings.only(
                left: 10.0,
              ),
              margin: Margins(left: Margin(0.0)),
              // backgroundColor: Colors.grey[100],
              border: const Border(
                left: BorderSide(color: Colors.grey, width: 4.0),
              ),
              fontStyle: FontStyle.italic,
              color: Theme.of(context).primaryColorLight,
            ),
          },
          // onImageError: (
          //   Object exception,
          //   StackTrace? stackTrace,
          // ) {
          //   developer.log(exception.toString());
          // },
        ),
        if (widget.comment.hasAttachments())
          widget.comment.getAttachments(context: context),
      ],
    );
  }
}
