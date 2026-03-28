import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InstagramEmbed extends StatefulWidget {
  const InstagramEmbed({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<InstagramEmbed> createState() => _InstagramEmbedState();
}

class _InstagramEmbedState extends State<InstagramEmbed>
    with AutomaticKeepAliveClientMixin<InstagramEmbed> {
  late final WebViewController _controller;
  Uri? _embedUri;
  double _height = 720.0;
  bool _loading = true;
  bool _error = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _embedUri = _buildEmbedUri(widget.url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _controller.runJavaScript('''
              const observer = new ResizeObserver(() => {
                InstagramResizeEvent.postMessage(
                  "" + Math.max(
                    document.body.scrollHeight,
                    document.documentElement.scrollHeight
                  )
                );
              });
              observer.observe(document.body);
              observer.observe(document.documentElement);
            ''');

            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;

            if (mounted) {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isInternalNavigation(request.url)) {
              return NavigationDecision.navigate;
            }

            launchUrl(
              Uri.parse(request.url),
              mode: LaunchMode.externalApplication,
            );
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'InstagramResizeEvent',
        onMessageReceived: (JavaScriptMessage message) {
          final newHeight = double.tryParse(message.message);
          if (newHeight == null || newHeight <= 0 || newHeight == _height) {
            return;
          }

          if (mounted) {
            setState(() => _height = newHeight);
          }
        },
      );

    if (_embedUri == null) {
      _loading = false;
      _error = true;
      return;
    }

    _controller.loadRequest(_embedUri!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error || _embedUri == null) {
      return OutlinedButton.icon(
        onPressed: () => launchUrl(
          Uri.parse(widget.url),
          mode: LaunchMode.externalApplication,
        ),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open Instagram post'),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: SizedBox(
        height: _height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: WebViewWidget(
            controller: _controller,
          ),
        ),
      ),
    );
  }

  Uri? _buildEmbedUri(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host != 'instagram.com' && host != 'www.instagram.com') {
      return null;
    }

    if (uri.pathSegments.length < 2) return null;

    final type = uri.pathSegments[0];
    final shortcode = uri.pathSegments[1];
    if (!const {'p', 'reel', 'reels'}.contains(type) || shortcode.isEmpty) {
      return null;
    }

    final embedType = type == 'reels' ? 'reel' : type;

    return Uri.https(
      'www.instagram.com',
      '/$embedType/$shortcode/embed/captioned/',
    );
  }

  bool _isInternalNavigation(String url) {
    if (_embedUri == null) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    if (url == 'about:blank') return true;
    if (uri.host == _embedUri!.host && uri.path.startsWith(_embedUri!.path)) {
      return true;
    }

    return false;
  }
}
