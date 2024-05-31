import 'dart:io';

import 'package:flutter/material.dart';

class LinkPreview extends StatefulWidget {
  final Uri primary;
  const LinkPreview({super.key, required this.primary});

  @override
  State<LinkPreview> createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  List<Uri> locations = [];

  bool resolved = false;
  bool infiniteLoop = false;
  bool inTooDeep = false;
  final limit = 8;

  Future<void> lookup() async {
    final client = HttpClient();

    var request = await client.getUrl(locations.last);
    request.followRedirects = false;

    var response = await request.close();

    if (response.isRedirect) {
      response.drain();
      final loc = response.headers.value(HttpHeaders.locationHeader);
      final nextUri = Uri.parse(loc!);

      if (locations.contains(nextUri)) {
        infiniteLoop = true;
        resolved = true;
      } else if (locations.length > limit) {
        locations.add(nextUri);
        inTooDeep = true;
        resolved = true;
      } else {
        locations.add(nextUri);
        lookup();
      }
    } else {
      resolved = true;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    // There's a problem where shortened links are being served with HTTP, when they should be HTTPS
    locations.add(widget.primary.replace(scheme: 'https'));
    lookup();
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
          SizedBox(
            width: 280.0,
            height: 160.0,
            child: ListView.builder(
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "${index + 1}. ${locations[index].toString()}",
                ),
              ),
              itemCount: locations.length,
              //prototypeItem: const Text(" "),
            ),
          ),
          const SizedBox(height: 10),
          if (inTooDeep) const Text("Too many hops. Gave up looking."),
          if (infiniteLoop)
            const Text("Infinite loop detected. Gave up looking."),
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
