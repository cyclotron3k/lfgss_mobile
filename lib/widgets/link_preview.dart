import 'dart:io';

import 'package:flutter/material.dart';

class LinkPreview extends StatefulWidget {
  final Uri primary;
  const LinkPreview({super.key, required this.primary});

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  Uri? location;
  bool resolved = false;
  bool error = false;

  Future<void> resolveRedirect() async {
    final client = HttpClient();

    var request = await client.getUrl(widget.primary);
    request.followRedirects = false;

    var response = await request.close();
    resolved = true;

    if (response.isRedirect) {
      response.drain();
      var loc = response.headers.value(HttpHeaders.locationHeader);
      location = Uri.parse(loc!);
    } else {
      error = true;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    resolveRedirect();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.primary.toString()),
          const SizedBox(height: 10),
          if (error) const Text("Could not determine final destination"),
          if (location != null) Text(location.toString()),
          if (!resolved)
            const SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
