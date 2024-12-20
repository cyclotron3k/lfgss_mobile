import 'package:flutter/material.dart';
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
  final int pages;
  final int pageSize = 100;
  List<Attachment>? attachmentList;

  CommentAttachments({
    required this.commentId,
    required this.attachments,
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

    Json json = await MicrocosmClient().getJson(uri);

    List<Attachment> items = json["attachments"]["items"]
        .map<Attachment>((item) => Attachment.fromJson(json: item))
        .toList();

    return items;
  }

  Future<List<Attachment>> getAttachmentList() async {
    attachmentList ??= await getPageOfChildren(0);
    return attachmentList!;
  }

  Widget build(BuildContext context) {
    return Consumer<Settings>(builder: (context, settings, child) {
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
        child: ListView.builder(
          itemCount: attachments,
          physics: physics,
          scrollDirection: scrollDirection,
          shrinkWrap: true,
          itemBuilder: getAttachment,
        ),
      );
    });
  }

  Widget getAttachment(BuildContext context, int index) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: FutureBuilder(
        future: getAttachmentList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black.withOpacity(0.8),
                    barrierDismissible: false,
                    pageBuilder: (context, _, __) => AttachmentGallery(
                      attachments: snapshot.data!,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: snapshot.data![index].build(context),
            );
          } else if (snapshot.hasError) {
            log(snapshot.error.toString());
            return Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64.0,
            );
          } else {
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
        },
      ),
    );
  }
}
