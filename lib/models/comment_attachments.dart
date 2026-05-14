import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' show log;

import '../constants.dart';
import '../services/microcosm_client.dart';
import '../services/settings.dart';
import '../widgets/attachment_gallery.dart';
import '../widgets/screens/settings_screen.dart';
import 'attachment.dart';

// TODO: refactor this whole file
// Maybe make it an ItemWithChildren

class CommentAttachments {
  final int commentId;
  final int attachments;
  final bool ignoreCache;
  final int pages;
  final int pageSize = 100;
  List<Attachment>? attachmentList;
  Future<List<Attachment>>? _attachmentListFuture;

  CommentAttachments({
    required this.commentId,
    required this.attachments,
    this.ignoreCache = true,
  }) : pages = (attachments / 100).ceil();

  Future<List<Attachment>> getPageOfChildren(int pageId) async {
    Uri uri = Uri.https(
      API_HOST,
      "/api/v1/comments/$commentId/attachments",
      {
        "limit": pageSize.toString(),
        "offset": (pageSize * pageId).toString(),
      },
    );

    Json json = await MicrocosmClient().getJson(uri, ignoreCache: ignoreCache);

    List<Attachment> items = json["attachments"]["items"]
        .map<Attachment>((item) => Attachment.fromJson(json: item))
        .toList();

    return items;
  }

  Future<List<Attachment>> getAttachmentList() {
    _attachmentListFuture ??= getPageOfChildren(0).then((items) {
      attachmentList = items;
      return items;
    }).catchError((error) {
      _attachmentListFuture = null;
      throw error;
    });

    return _attachmentListFuture!;
  }

  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, _) {
      Layout layout = Layout.values.byName(
        settings.getString("layout") ?? "horizontalSmall",
      );

      double? height = switch (layout) {
        Layout.horizontalLarge => 440.0,
        Layout.horizontalSmall => 220.0,
        Layout.vertical => null,
      };

      ScrollPhysics? physics = switch (layout) {
        Layout.horizontalLarge => null,
        Layout.horizontalSmall => null,
        Layout.vertical => const ClampingScrollPhysics(),
      };

      Axis scrollDirection = switch (layout) {
        Layout.horizontalLarge => Axis.horizontal,
        Layout.horizontalSmall => Axis.horizontal,
        Layout.vertical => Axis.vertical,
      };

      return SizedBox(
        height: height,
        width: double.infinity,
        child: FutureBuilder<List<Attachment>>(
          future: getAttachmentList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final visibleAttachments =
                  snapshot.data!.take(attachments).toList(growable: false);

              return ListView.builder(
                itemCount: visibleAttachments.length,
                physics: physics,
                scrollDirection: scrollDirection,
                shrinkWrap: true,
                itemBuilder: (context, index) => getAttachment(
                  context,
                  visibleAttachments,
                  index,
                ),
              );
            } else if (snapshot.hasError) {
              log(snapshot.error.toString());
              return Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 64.0,
              );
            } else {
              return ListView.builder(
                itemCount: attachments,
                physics: physics,
                scrollDirection: scrollDirection,
                shrinkWrap: true,
                itemBuilder: (context, _) => _loadingAttachment(context),
              );
            }
          },
        ),
      );
    });
  }

  Widget getAttachment(
    BuildContext context,
    List<Attachment> attachments,
    int index,
  ) {
    final attachment = attachments[index];

    return AnimatedSize(
      key: ValueKey(attachment.fileHash),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black.withAlpha(204),
              barrierDismissible: false,
              pageBuilder: (context, _, __) => AttachmentGallery(
                attachments: attachments,
                initialIndex: index,
              ),
            ),
          );
        },
        onLongPress: attachment.isImage
            ? () async => _showImageActions(
                  context,
                  attachment,
                )
            : null,
        child: attachment.build(context),
      ),
    );
  }

  Widget _loadingAttachment(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          color: Colors.grey.shade800,
          child: AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 32.0,
                  maxWidth: 32.0,
                ),
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showImageActions(
    BuildContext context,
    Attachment attachment,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy URL'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: attachment.url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attachment URL copied')),
                  );
                }
                if (bottomSheetContext.mounted) {
                  Navigator.pop(bottomSheetContext);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.adaptive.share),
              title: const Text('Share'),
              onTap: () async {
                if (bottomSheetContext.mounted) {
                  Navigator.pop(bottomSheetContext);
                }
                await attachment.share();
              },
            ),
          ],
        ),
      ),
    );
  }
}
