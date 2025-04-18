import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:universal_html/html.dart' as html;

/// Callback for receiving the authentication token
typedef YxAuthTokenCallback = void Function(String token);

/// Main class for Yandex ID authentication
class YxAuth {
  final String clientId;
  final String redirectUri;
  final String domain;
  final String origin;
  final String state;
  final YxAuthTokenCallback onTokenReceived;

  YxAuth({
    required this.clientId,
    required this.redirectUri,
    required this.domain,
    required this.origin,
    required this.state,
    required this.onTokenReceived,
  });

  /// Checks the current URL for a token and calls [onTokenReceived] if found (Web only).
  void handleRedirectOnWebIfPresent() {
    if (!kIsWeb) return;
    final uri = Uri.base;
    if (uri.toString().startsWith(redirectUri) && uri.hasFragment) {
      final params = Uri.splitQueryString(uri.fragment);
      if (params.containsKey('access_token')) {
        final token = params['access_token']!;
        onTokenReceived(token);
      }
    }
  }

  /// Starts the authentication process.
  /// For Web, redirects to the OAuth page.
  Future<void> signIn({BuildContext? context}) async {
    final authUrl = buildAuthUrl();
    if (kIsWeb) {
      html.window.location.href = authUrl;
      return;
    } else {
      if (context == null) {
        throw Exception('context is required for non-web platforms');
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _YxAuthWebViewScreen(
            authUrl: authUrl,
            redirectUri: redirectUri,
            onTokenReceived: onTokenReceived,
          ),
        ),
      );
      return;
    }
  }

  /// Builds the OAuth authorization URL.
  String buildAuthUrl() {
    return 'https://$domain/authorize'
        '?response_type=token'
        '&client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&state=$state'
        '&force_confirm=true'
        '&origin=$origin';
  }
}

/// Internal WebView screen for authentication (mobile/desktop)
class _YxAuthWebViewScreen extends StatefulWidget {
  final String authUrl;
  final String redirectUri;
  final YxAuthTokenCallback onTokenReceived;

  const _YxAuthWebViewScreen({
    required this.authUrl,
    required this.redirectUri,
    required this.onTokenReceived,
  });

  @override
  State<_YxAuthWebViewScreen> createState() => _YxAuthWebViewScreenState();
}

class _YxAuthWebViewScreenState extends State<_YxAuthWebViewScreen> {
  bool _tokenDelivered = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.authUrl)),
          onLoadStart: (controller, url) {
            if (_tokenDelivered) return;
            if (url != null && url.toString().startsWith(widget.redirectUri)) {
              final uri = Uri.parse(url.toString());
              if (uri.fragment.isNotEmpty) {
                final params = Uri.splitQueryString(uri.fragment);
                if (params.containsKey('access_token')) {
                  final token = params['access_token']!;
                  _tokenDelivered = true;
                  widget.onTokenReceived(token);
                  if (mounted) Navigator.of(context).pop();
                }
              }
            }
          },
        ),
      ),
    );
  }
}
