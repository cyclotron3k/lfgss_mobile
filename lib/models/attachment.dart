import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../widgets/maybe_image.dart';

class Attachment {
  final int profileId;
  final String fileHash;
  final String fileName;
  final String fileExt;
  final DateTime created;
  final String _url;

  Attachment.fromJson({required json})
      : profileId = json["profileId"],
        fileHash = json["fileHash"],
        fileName = json["fileName"],
        fileExt = json["fileExt"],
        created = DateTime.parse(json["created"]),
        _url = json["meta"]["links"][0]["href"]; // TODO: be more robust

  String get url => _url.startsWith('/') ? "https://$API_HOST$_url" : _url;

  final imageExtMatcher = RegExp(
    r"^(jpe?g|png|webp|heic|gif)$",
    multiLine: false,
    caseSensitive: false,
  );
  bool get isImage => imageExtMatcher.hasMatch(fileExt);

  Widget build(BuildContext context) {
    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
        child: MaybeImage(
          imageUrl: url,
          imageBuilder: (context, imageProvider) => ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image(
              image: imageProvider,
              fit: BoxFit.contain,
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.error_outline,
          ),
        ),
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
              child: InkWell(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fileName),
                      const SizedBox(height: 8.0),
                      const Icon(Icons.download),
                    ],
                  ),
                ),
                onTap: () async => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
