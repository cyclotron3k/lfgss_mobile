import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/screens/settings_screen.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../services/microcosm_client.dart';
import '../services/settings.dart';
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
    Uri uri = Uri.parse(
      "https://$HOST/api/v1/comments/$commentId/attachments?limit=$pageSize&offset=${pageSize * pageId}",
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
          // prototypeItem: const Icon(Icons.image, size: 64.0),
          itemBuilder: getAttachment,
        ),
      );
    });
  }

  Widget getAttachment(BuildContext context, int index) {
    return FutureBuilder(
      future: getAttachmentList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // return const SizedBox(width: 100.0, height: 158.0);
          return snapshot.data![index].build(context);
        } else if (snapshot.hasError) {
          return Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 64.0,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
