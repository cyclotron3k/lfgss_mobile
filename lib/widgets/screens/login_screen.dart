import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants.dart';
import '../../services/microcosm_client.dart';
import '../../services/settings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController controller;
  final WebviewCookieManager cookieManager = WebviewCookieManager();
  int loadingPercentage = 0;
  bool complete = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) async {
          var settings = Provider.of<Settings>(context, listen: false);

          List<Cookie> cookies = await cookieManager.getCookies(
            'www.lfgss.com',
          );

          String? accessToken;
          for (Cookie cookie in cookies) {
            if (cookie.name == "access_token") {
              accessToken = cookie.value;
              break;
            }
          }

          if (accessToken != null) {
            await settings.setString("accessToken", accessToken);
            await MicrocosmClient().updateAccessToken();

            if (!context.mounted) return;
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
          if (url == 'https://www.lfgss.com/') {
            // Disable Google SSO button because it doesn't work in a WebView:
            await controller.runJavaScript("""
              document.getElementById("login").click();
              document.querySelectorAll("#auth0-lock-container-1 .auth0-lock-close-button")[0].style.visibility = "hidden";
              document.querySelectorAll("#auth0-lock-container-1 button[data-provider=google-oauth2]")[0].disabled = true;
              document.querySelectorAll("#auth0-lock-container-1 button[data-provider=google-oauth2]")[0].style.filter = "saturate(0%)";
            """);
            loadingPercentage = 100;
            complete = true;
          }
        },
        // onUrlChange: (change) {
        //   log(change.url ?? "No url");
        // },
        // onWebResourceError: (WebResourceError error) {},
        // onNavigationRequest: (NavigationRequest request) {
        //   if (request.url.startsWith('https://www.lfgss.com/')) {
        //     return NavigationDecision.navigate;
        //   }
        //   return NavigationDecision.prevent;
        // },
      ))
      ..setUserAgent(
        MicrocosmClient.userAgent,
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.lfgss.com/'));
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
