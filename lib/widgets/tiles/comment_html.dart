import 'package:flutter/material.dart' hide Element;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_iframe/flutter_html_iframe.dart';
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' show parse;
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../models/reply_notifier.dart';
import '../../services/link_parser.dart';
import '../image_gallery.dart';
import '../maybe_image.dart';
import '../missing_image.dart';
import '../tweet.dart';

class CommentHtml extends StatefulWidget {
  final bool selectable;
  final bool embedTweets;
  final bool embedYouTube;
  final String html;
  final Comment? replyTarget;

  const CommentHtml({
    super.key,
    required this.html,
    this.selectable = false,
    this.embedTweets = false,
    this.embedYouTube = false,
    this.replyTarget,
  });

  @override
  State<CommentHtml> createState() => _CommentHtmlState();
}

class _CommentHtmlState extends State<CommentHtml> {
  String _selectedText = "";

  late final Document _doc;

  @override
  void initState() {
    super.initState();

    _doc = parse(widget.html);

    final RegExp tweetMatcher = RegExp(
      r'^https://(twitter|x)\.com/\w+/status/\d+',
    );
    if (widget.embedTweets) {
      final anchors = _doc.querySelectorAll('a');
      for (final anchor in anchors) {
        // There are soft hyphens in the text, to help web
        // layout, but it doesn't help us
        final cleaned = anchor.text.replaceAll('\xad', '');
        if (!tweetMatcher.hasMatch(cleaned)) continue;
        // _tweetsPresent = true;
        anchor.replaceWith(
          Element.html('<tweet>$cleaned</tweet>'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.selectable
        ? withSelection(context)
        : withoutSelection(context);
  }

  Widget withSelection(BuildContext context) => SelectionArea(
        onSelectionChanged: (value) => _selectedText = value?.plainText ?? "",
        contextMenuBuilder: (innerContext, selectableRegionState) =>
            AdaptiveTextSelectionToolbar(
          anchors: selectableRegionState.contextMenuAnchors,
          children: AdaptiveTextSelectionToolbar.getAdaptiveButtons(
            innerContext,
            [
              ...selectableRegionState.contextMenuButtonItems,
              if (widget.replyTarget != null)
                ContextMenuButtonItem(
                    label: "Reply",
                    onPressed: () {
                      context.read<ReplyNotifier?>()?.setReplyTarget(
                            widget.replyTarget!,
                            text: _selectedText,
                          );
                      ContextMenuController.removeAny();
                    }),
            ],
          ).toList(),
        ),
        child: withoutSelection(context),
      );

  Widget withoutSelection(BuildContext context) => Html.fromDom(
        document: _doc,
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
              return GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    ImageGallery(
                      url: ec.attributes["src"]!,
                      heroTag: ec.attributes["src"]!,
                    ),
                  );
                },
                child: MaybeImage(
                  imageUrl: ec.attributes["src"]!,
                  imageBuilder: (context, imageProvider) => ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image(image: imageProvider),
                  ),
                  errorWidget: (context, url, error) => const SizedBox(
                    width: 64,
                    child: MissingImage(),
                  ),
                ),
              );
            },
          ),
          if (widget.embedYouTube) const IframeHtmlExtension(),
          if (widget.embedTweets)
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
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
        },
      );
}
