import 'package:flutter/material.dart';
// import 'dart:developer' as developer;

import '../constants.dart';
import '../api/microcosm_client.dart';
import 'attachment.dart';

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

  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.0,
      width: double.infinity,
      child: ListView.builder(
        itemCount: attachments,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        // prototypeItem: const Icon(Icons.image, size: 64.0),
        itemBuilder: getAttachment,
      ),
    );
  }
}
