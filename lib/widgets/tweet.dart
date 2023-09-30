import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Tweet extends StatefulWidget {
  final String url;
  const Tweet({
    super.key,
    required this.url,
  });

  @override
  State<Tweet> createState() => _TweetState();
}

class _TweetState extends State<Tweet> {
  late Future<Map<String, dynamic>> payload;
  late WebViewController controller;
  bool loading = true;
  bool error = false;
  double height = 256.0;

  @override
  void initState() {
    super.initState;
    controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          controller.runJavaScript("""
            const resizeObserver = new ResizeObserver(entries =>
              ResizeEventListener.postMessage("" + document.body.scrollHeight)
            );
            resizeObserver.observe(document.body);
          """);
        },
        onNavigationRequest: (NavigationRequest request) {
          launchUrl(
            Uri.parse(request.url),
            mode: LaunchMode.externalApplication,
          );
          return NavigationDecision.prevent;
        },
      ))
      ..addJavaScriptChannel(
        'ResizeEventListener',
        onMessageReceived: (JavaScriptMessage message) {
          final double newHeight = int.parse(message.message).toDouble();
          if (height != newHeight) {
            setState(() => height = newHeight);
          }
        },
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    // TODO: Don't ignore the setting override
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    Uri oembed = Uri.https("publish.twitter.com", "/oembed", {
      "url": widget.url,
      "dnt": "true",
      "theme": isDarkMode ? "dark" : "light",
    });

    http.get(oembed).then<Map<String, dynamic>>((response) {
      if (response.statusCode != 200) throw Exception("Probably missing?");
      String page = const Utf8Decoder().convert(response.body.codeUnits);
      return json.decode(page);
    }).then((response) {
      // TODO: Don't guess colours
      controller.loadHtmlString("""
        <html lang="en" dir="ltr">
        <head>
          <meta charset="utf-8">
          <title>Twitter Publish</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimal-ui">
        </head>
        <body style="background-color:#${isDarkMode ? "1c1b1f" : "eee"};">
        ${response["html"]}
        </body>
        </html>
      """);
      setState(() => loading = false);
    }, onError: (_) {
      setState(() {
        loading = false;
        error = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error) {
      return const Center(
        child: Icon(Icons.error, size: 22.0),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: SizedBox(
        height: height,
        child: WebViewWidget(
          controller: controller,
        ),
      ),
    );
  }
}
