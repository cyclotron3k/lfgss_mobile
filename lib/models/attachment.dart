import 'package:flutter/material.dart';

import '../constants.dart';
import '../widgets/image_gallery.dart';
import '../widgets/maybe_image.dart';

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
    return url.startsWith('/') ? "https://$API_HOST$url" : url;
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            ImageGallery(
              url: url,
              heroTag: fileHash,
              fileName: fileName,
            ),
          );
        },
        child: MaybeImage(
          fit: BoxFit.contain,
          imageUrl: getUrl(),
          imageBuilder: (context, imageProvider) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image(image: imageProvider),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.error_outline,
          ),
        ),
      ),
    );
  }
}
