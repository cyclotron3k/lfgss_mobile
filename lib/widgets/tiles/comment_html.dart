import 'dart:developer';

import 'package:flutter/material.dart' hide Element;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' show parse;
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../models/comment.dart';
import '../../models/comment_shuttle.dart';
import '../../services/link_parser.dart';
import 'iframe_embed.dart';
import 'instagram_embed.dart';
import '../image_gallery.dart';
import '../maybe_image.dart';
import '../missing_image.dart';
import '../tweet.dart';

class CommentHtml extends StatefulWidget {
  final bool selectable;
  final bool embedTweets;
  final bool embedYouTube;
  final bool embedInstagram;
  final String html;
  final Comment? replyTarget;

  const CommentHtml({
    super.key,
    required this.html,
    this.selectable = false,
    this.embedTweets = false,
    this.embedYouTube = false,
    this.embedInstagram = false,
    this.replyTarget,
  });

  @override
  State<CommentHtml> createState() => _CommentHtmlState();
}

class _CommentHtmlState extends State<CommentHtml> {
  String _selectedText = "";
  late final Document _doc;
  static const _iframeReferer = 'https://$WEB_HOST/';

  @override
  void initState() {
    super.initState();

    _doc = parse(widget.html);

    // The BRs following IFRAMEs cause layout issues, so remove them:
    _doc.querySelectorAll("iframe + br").forEach((ele) => ele.remove());

    // The BRs that are inserted into lists cause havoc too:
    _doc.querySelectorAll("li > br:last-child").forEach((ele) => ele.remove());

    final tweetMatcher = RegExp(r'^https://(twitter|x)\.com/\w+/status/\d+');
    final instagramMatcher = RegExp(
      r'^https?://(?:www\.)?instagram\.com/(?:p|reel|reels)/[A-Za-z0-9_-]+/?(?:\?.*)?$',
    );

    if (widget.embedTweets || widget.embedInstagram) {
      final anchors = _doc.querySelectorAll('a');
      for (final anchor in anchors) {
        // There are soft hyphens in the text, to help web
        // layout, but it doesn't help us
        final cleanedText = anchor.text.replaceAll('\xad', '');
        final cleanedHref =
            (anchor.attributes["href"] ?? "").replaceAll('\xad', '');
        final candidate = cleanedHref.isNotEmpty ? cleanedHref : cleanedText;

        if (widget.embedTweets && tweetMatcher.hasMatch(candidate)) {
          anchor.replaceWith(Element.tag('tweet')..text = candidate);
          continue;
        }

        if (widget.embedInstagram && instagramMatcher.hasMatch(candidate)) {
          anchor.replaceWith(Element.tag('instagram')..text = candidate);
        }
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
                      context.read<CommentShuttle?>()?.setReplyTarget(
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
          const TableHtmlExtension(),
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
                  errorWidget: (context, url, error) {
                    log("Error loading image", error: error);
                    return const SizedBox(
                      width: 48,
                      child: MissingImage(),
                    );
                  },
                ),
              );
            },
          ),
          if (widget.embedYouTube)
            TagExtension(
              tagsToExtend: {"iframe"},
              builder: (context) => Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: IframeEmbed(
                  src: context.attributes["src"],
                  width: context.attributes["width"],
                  height: context.attributes["height"],
                  referer: _iframeReferer,
                ),
              ),
            ),
          if (widget.embedTweets)
            TagExtension(
              tagsToExtend: {"tweet"},
              builder: (context) => Tweet(url: context.innerHtml),
            ),
          if (widget.embedInstagram)
            TagExtension(
              tagsToExtend: {"instagram"},
              builder: (context) => Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: InstagramEmbed(url: context.innerHtml),
              ),
            ),
        ],
        style: {
          "p": Style(
            margin: Margins.only(top: 0.0, bottom: 8.0),
          ),
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
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          "a": Style.fromTextStyle(
            const TextStyle(
              // See: https://github.com/Sub6Resources/flutter_html/issues/1361
              decorationColor: Colors.blue,
            ),
          ),
          "pre": Style(
            backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            padding: HtmlPaddings.only(
              left: 4.0,
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
