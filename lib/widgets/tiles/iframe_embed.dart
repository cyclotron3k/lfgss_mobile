import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IframeEmbed extends StatefulWidget {
  const IframeEmbed({
    super.key,
    required this.src,
    required this.width,
    required this.height,
    required this.referer,
  });

  final String? src;
  final String? width;
  final String? height;
  final String referer;

  @override
  State<IframeEmbed> createState() => _IframeEmbedState();
}

class _IframeEmbedState extends State<IframeEmbed> {
  WebViewController? _controller;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();

    var src = widget.src;
    if (src == null || src.isEmpty) return;
    if (src.startsWith("//")) src = "https:$src";

    final uri = Uri.tryParse(src);
    if (uri == null) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        uri,
        headers: <String, String>{
          'Referer': widget.referer,
        },
      );

    _lifecycleListener = AppLifecycleListener(
      onPause: _pauseMedia,
    );
  }

  void _pauseMedia() {
    // Pause all HTML5 <video> elements.
    // Also send the YouTube Player API postMessage command for iframes.
    _controller?.runJavaScript(
      'document.querySelectorAll("video").forEach(function(v){ try{ v.pause(); }catch(e){} });'
      'document.querySelectorAll("iframe").forEach(function(f){'
      '  try{ f.contentWindow.postMessage(\'{"event":"command","func":"pauseVideo","args":[]}\', "*"); }catch(e){}'
      '});',
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: _aspectRatio(),
      child: WebViewWidget(
        controller: _controller!,
      ),
    );
  }

  double _aspectRatio() {
    final width = double.tryParse(widget.width ?? "");
    final height = double.tryParse(widget.height ?? "");
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
    return 16 / 9;
  }
}
