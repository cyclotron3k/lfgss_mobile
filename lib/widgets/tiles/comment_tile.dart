import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
// import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/comment.dart';
import '../../services/link_parser.dart';
import '../maybe_image.dart';
import '../missing_image.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final bool highlight;
  const CommentTile({super.key, required this.comment, this.highlight = false});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final List<String> validSchemes = ['https', 'http', 'mailto', 'tel'];
  final RegExp profileMatcher = RegExp(r'^/profiles/(\d+)$');
  final RegExp hashtagMatcher = RegExp(r'^/search/\?q=(%23\w+)$');
  final RegExp commentMatcher = RegExp(r'^/comments/(\d+)$');

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
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
                  InkWell(
                    onTap: () {
                      showModalBottomSheet<void>(
                        enableDrag: true,
                        showDragHandle: true,
                        context: context,
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
                                  errorWidget: (context, url, error) =>
                                      const Icon(
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
                  Expanded(
                    child: widget.comment.links.containsKey("inReplyToAuthor")
                        ? InkWell(
                            onTap: () async {
                              LinkParser.parseUri(
                                context,
                                widget.comment.links["inReplyTo"]!.href,
                              );
                            },
                            child: Text(
                              " replied to ${widget.comment.links["inReplyToAuthor"]!.title}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : const Text(""),
                  ),
                  if (widget.comment.revisions > 1)
                    const Text(
                      " Edited • ",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: DateFormat.yMMMEd().add_Hms().format(
                              widget.comment.created,
                            ),
                        child: Text(
                          timeago.format(widget.comment.created),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Html(
                data: widget.comment.html,
                onLinkTap: (
                  String? url,
                  Map<String, String> attributes,
                  element, // From 'package:html/dom.dart', not material
                ) async {
                  await LinkParser.parseLink(context, url ?? "");
                },
                extensions: [
                  ImageExtension(
                    handleNetworkImages: true,
                    handleAssetImages: false,
                    handleDataImages: false,
                    builder: (ExtensionContext ec) {
                      return MaybeImage(
                        imageUrl: ec.attributes["src"]!,
                        imageBuilder: (context, imageProvider) => ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image(image: imageProvider),
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
                  "a": Style.fromTextStyle(
                    const TextStyle(
                      // See: https://github.com/Sub6Resources/flutter_html/issues/1361
                      decorationColor: Colors.blue,
                    ),
                  ),
                  "body": Style(
                    // TODO: Workaround for the above issue. Remove when resolved
                    textDecorationColor: Colors.blue,
                  ),
                },
              ),
              if (widget.comment.hasAttachments())
                widget.comment.getAttachments(context: context),
            ],
          ),
        ],
      ),
    );
  }
}
