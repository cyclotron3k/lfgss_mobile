import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_iframe/flutter_html_iframe.dart';
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' show parse;
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/comment.dart';
import '../../services/link_parser.dart';
import '../../services/settings.dart';
import '../maybe_image.dart';
import '../missing_image.dart';
import '../tweet.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final bool highlight;
  const CommentTile({super.key, required this.comment, this.highlight = false});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late final Document doc;
  late final Document orig;

  late final bool showEdited;
  late final bool showReplied;

  @override
  void initState() {
    super.initState();

    showEdited = widget.comment.revisions > 1;
    showReplied = widget.comment.links.containsKey("inReplyToAuthor");

    final RegExp tweetMatcher = RegExp(
      r'^https://twitter\.com/\w+/status/\d+$',
    );
    doc = parse(widget.comment.html);
    orig = doc.clone(true); // TODO: don't be lazy
    final anchors = doc.querySelectorAll('a');
    for (final anchor in anchors) {
      // There are soft hyphens in the text, to help layout, but it doesn't help us
      final cleaned = anchor.text.replaceAll('\xad', '');
      if (!tweetMatcher.hasMatch(cleaned)) continue;
      anchor.replaceWith(
        Element.html('<tweet>${cleaned}</tweet>'),
      );
    }
  }

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
              _titleBar(context),
              Consumer<Settings>(
                builder: (context, settings, _) => Html.fromDom(
                  document: (settings.getBool(
                            'embedTweets',
                          ) ??
                          true)
                      ? doc
                      : orig,
                  // data: widget.comment.html,
                  onLinkTap: (
                    String? url,
                    Map<String, String> attributes,
                    element, // From 'package:html/dom.dart', not material
                  ) async {
                    await LinkParser.parseLink(context, url ?? "");
                  },
                  extensions: [
                    if (settings.getBool('embedYouTube') ?? true)
                      const IframeHtmlExtension(),
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
                    ),
                    TagExtension(
                      tagsToExtend: {"tweet"},
                      builder: (context) => Tweet(url: context.innerHtml),
                    ),
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
              ),
              if (widget.comment.hasAttachments())
                widget.comment.getAttachments(context: context),
            ],
          ),
        ],
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
          flex: showReplied ? 2 : 1,
          child: Wrap(
            spacing: 4.0,
            children: [
              InkWell(
                onTap: () => _showProfileModal(context),
                child: Text(
                  widget.comment.createdBy.profileName,
                ),
              ),
              if (showReplied)
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
          flex: showEdited ? 2 : 1,
          child: Wrap(
            runAlignment: WrapAlignment.end,
            alignment: WrapAlignment.end,
            spacing: 4.0,
            children: [
              if (showEdited)
                const Text(
                  "Edited •",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              Tooltip(
                message: DateFormat.yMMMEd().add_Hms().format(
                      widget.comment.created,
                    ),
                child: Text(
                  timeago.format(widget.comment.created),
                  style: const TextStyle(color: Colors.grey),
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
}
