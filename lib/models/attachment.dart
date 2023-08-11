import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

// import 'dart:developer' as developer;

class Attachment {
  final int profileId;
  final String fileHash;
  final String fileName;
  final String fileExt;
  final DateTime created;
  final String url;

  Attachment.fromJson({required json})
      : profileId = json["profileId"],
        fileHash = json["fileHash"],
        fileName = json["fileName"],
        fileExt = json["fileExt"],
        created = DateTime.parse(json["created"]),
        url = json["meta"]["links"][0]["href"]; // TODO: be more robust

  String getUrl() {
    return url.startsWith('/') ? "https://$HOST$url" : url;
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: CachedNetworkImage(
          imageUrl: getUrl(),
          height: 128.0,
          progressIndicatorBuilder: (context, url, downloadProgress) => Center(
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
          errorWidget: (context, url, error) => const Icon(
            Icons.error,
          ),
        ),
      ),
    );
  }
}
