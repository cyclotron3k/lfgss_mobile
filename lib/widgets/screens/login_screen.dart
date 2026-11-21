import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants.dart';
import '../../notifications.dart';
import '../../services/microcosm_client.dart';
import '../../services/settings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const cookieChannel = MethodChannel(
    'com.lfgss.lfgss_mobile/web_cookies',
  );
  late final WebViewController controller;
  int loadingPercentage = 0;
  bool complete = false;

  @override
  void setState(VoidCallback fn) {
    if (context.mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) async {
          var settings = Provider.of<Settings>(context, listen: false);

          final cookieString = await cookieChannel.invokeMethod<String>(
            'getCookies',
            {'url': 'https://$WEB_HOST/'},
          );
          String? accessToken;
          for (final cookie in (cookieString ?? '').split(';')) {
            final pair = cookie.trim().split('=');
            if (pair.length >= 2 && pair.first == 'access_token') {
              accessToken = pair.skip(1).join('=');
              break;
            }
          }

          if (accessToken != null) {
            await MicrocosmClient().saveAccessToken(accessToken);
            await syncNotificationTask(settings.prefs, requestPermission: true);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful'),
                duration: TOAST_DURATION,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          } else {
            setState(() => loadingPercentage = 0);
          }
        },
        onProgress: (progress) {
          setState(() => loadingPercentage = progress);
        },
        onPageFinished: (url) async {
          if (url == "https://$WEB_HOST/") {
            // Disable Google SSO button because it doesn't work in a WebView:
            await controller.runJavaScript("""
              document.getElementById("login").click();
              document.querySelectorAll("#auth0-lock-container-1 .auth0-lock-close-button")[0].style.visibility = "hidden";
              document.querySelectorAll("#auth0-lock-container-1 button[data-provider=google-oauth2]")[0].disabled = true;
              document.querySelectorAll("#auth0-lock-container-1 button[data-provider=google-oauth2]")[0].style.filter = "saturate(0%)";
            """);
            loadingPercentage = 100;
            complete = true;
            setState(() {});
          }
        },
        // onUrlChange: (change) {
        //   log(change.url ?? "No url");
        // },
        // onWebResourceError: (WebResourceError error) {},
        // onNavigationRequest: (NavigationRequest request) {
        //   if (request.url.startsWith('https://$WEB_HOST/')) {
        //     return NavigationDecision.navigate;
        //   }
        //   return NavigationDecision.prevent;
        // },
      ))
      ..setUserAgent(MicrocosmClient.userAgent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://$WEB_HOST/'));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: WebViewWidget(
                controller: controller,
              ),
            ),
          ),
        ),
        if (!complete)
          const Opacity(
            opacity: 0.8,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (!complete)
          Center(
            child: CircularProgressIndicator(
              value: loadingPercentage / 100,
            ),
          ),
      ],
    );
  }
}
