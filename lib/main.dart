import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:universal_html/html.dart' as html;

const String authUrl = "https://oauth.yandex.ru/authorize"
    "?response_type=token"
    "&client_id=bcc75242b623416cb7e4068ad50ac408"
    "&redirect_uri=http://localhost:8000/callback"
    "&state=test"
    "&force_confirm=true"
    "&origin=yandex_auth_sdk_android_v3";
const String redirectUriString = 'http://localhost:8000/callback';
const String tokenParamName = 'access_token';
const String prefsTokenKey = 'auth_token';

final Uri redirectUri = Uri.parse(redirectUriString);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cross-Platform Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Builder(builder: (context) => const AuthScreen()),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTokenFromPrefs();

    if (kIsWeb) {
      _checkUrlForToken();
    }
  }

  Future<void> _loadTokenFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(prefsTokenKey);
      if (savedToken != null && savedToken.isNotEmpty) {
        if (mounted) {
          setState(() {
            _token = savedToken;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading token: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading saved token.";
        });
      }
    }
  }

  void _checkUrlForToken() {
    final Uri currentUri = Uri.base;
    debugPrint("Web: Checking initial URL: $currentUri");

    if (currentUri.toString().startsWith(redirectUriString)) {
      debugPrint("Web: URL matches redirect URI.");

      if (currentUri.hasFragment && currentUri.fragment.isNotEmpty) {
        debugPrint("Web: URL has fragment: ${currentUri.fragment}");
        final Map<String, String> fragmentParams =
            Uri.splitQueryString(currentUri.fragment);

        if (fragmentParams.containsKey(tokenParamName)) {
          final String? potentialToken = fragmentParams[tokenParamName];
          debugPrint("Web: Found potential token in fragment: $potentialToken");

          if (potentialToken != null && potentialToken.isNotEmpty) {
            _saveToken(potentialToken);

            final path = Uri.parse(redirectUriString).path;
            html.window.history
                .replaceState(null, '', path.isEmpty ? '/' : path);
            debugPrint("Web: Token processed and URL cleaned to path: $path");
          } else {
            debugPrint("Web: Token parameter found in fragment but empty.");
            if (mounted) {
              setState(() => _errorMessage =
                  "Token parameter found in fragment but empty.");
            }
          }
        } else {
          debugPrint(
              "Web: Token parameter '$tokenParamName' not found in fragment.");
          if (mounted) {
            setState(() => _errorMessage =
                "Token parameter '$tokenParamName' not found in fragment.");
          }
        }
      } else {
        if (currentUri.queryParameters.containsKey(tokenParamName)) {
          debugPrint(
              "Web: Fallback check - Found token in query parameters (unexpected?).");
          final String? potentialToken =
              currentUri.queryParameters[tokenParamName];
          if (potentialToken != null && potentialToken.isNotEmpty) {
            _saveToken(potentialToken);
            final path = Uri.parse(redirectUriString).path;
            html.window.history
                .replaceState(null, '', path.isEmpty ? '/' : path);
            debugPrint(
                "Web: Token from query processed and URL cleaned to path: $path");
          } else {
            debugPrint("Web: Token parameter found in query but empty.");
            if (mounted) {
              setState(() =>
                  _errorMessage = "Token parameter found in query but empty.");
            }
          }
        } else {
          debugPrint(
              "Web: URL does not contain the token in fragment or query parameters.");
          if (mounted) {
            setState(() => _errorMessage =
                "Authentication callback received, but no token found.");
          }
        }
      }
    } else {
      debugPrint("Web: Initial URL does not match redirect URI.");
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsTokenKey, token);
      if (mounted) {
        setState(() {
          _token = token;
          _isLoading = false;
          _errorMessage = null;
        });
      }
      debugPrint("Token saved successfully: $token");
    } catch (e) {
      debugPrint("Error saving token: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to save token.";
        });
      }
    }
  }

  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsTokenKey);
      if (mounted) {
        setState(() {
          _token = null;
          _errorMessage = null;
        });
      }
      debugPrint("Token cleared.");
    } catch (e) {
      debugPrint("Error clearing token: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to clear token.";
        });
      }
    }
  }

  Future<void> _startAuthentication() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (kIsWeb) {
      _authenticateWithWebRedirect();
    } else {
      await _authenticateWithWebView(context);
    }
  }

  void _authenticateWithWebRedirect() {
    debugPrint("Web: Redirecting to auth URL: $authUrl");
    html.window.location.href = authUrl;
  }

  Future<void> _authenticateWithWebView(BuildContext context) async {
    debugPrint("Non-Web: Opening WebView for URL: $authUrl");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewAuthScreen(
          initialUrl: authUrl,
          redirectUri: redirectUri,
          onTokenReceived: (token) async {
            debugPrint("WebView: Token received: $token");
            await _saveToken(token);
            const popDelay = Duration(milliseconds: 200);
            debugPrint("WebView: Delaying pop by $popDelay to allow WebView to settle...");
            if (mounted) {
              await Future.delayed(popDelay);
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
                debugPrint("WebView: Popped screen after delay.");
              } else {
                debugPrint("WebView: Cannot pop screen after delay (unmounted or cannot pop).");
              }
            }
          },
          onError: (error) {
            debugPrint("WebView: Error received: $error");
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = "WebView Auth Error: $error";
              });
            }
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );

    if (mounted && _token == null) {
      setState(() {
        _isLoading = false;
        if (_errorMessage == null) {
          debugPrint("WebView closed without obtaining token.");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_token != null)
                Column(
                  children: [
                    const Text('Вы успешно авторизованы!',
                        style: TextStyle(fontSize: 18, color: Colors.green)),
                    const SizedBox(height: 15),
                    Text('Ваш токен (показан для примера):\n$_token',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _clearToken,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Выйти'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const Text(
                      'Нажмите кнопку, чтобы начать авторизацию.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _startAuthentication,
                      child: const Text('Авторизоваться'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WebViewAuthScreen extends StatefulWidget {
  final String initialUrl;
  final Uri redirectUri;
  final Function(String) onTokenReceived;
  final Function(String)? onError;

  const WebViewAuthScreen({
    super.key,
    required this.initialUrl,
    required this.redirectUri,
    required this.onTokenReceived,
    this.onError,
  });

  @override
  State<WebViewAuthScreen> createState() => _WebViewAuthScreenState();
}

class _WebViewAuthScreenState extends State<WebViewAuthScreen> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _pageLoadingError = false;
  String? _errorMessage;

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewSettings settings = InAppWebViewSettings(
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Авторизация"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController?.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              _webViewController = controller;
              debugPrint("WebView created");
            },
            onLoadStart: (controller, url) {
              debugPrint("WebView onLoadStart: $url");
              if (mounted) {
                setState(() {
                  _pageLoadingError = false;
                  _errorMessage = null;
                });
              }
            },
            onLoadStop: (controller, url) async {
              debugPrint("WebView onLoadStop: $url");
              if (mounted) {
                setState(() {
                  _progress = 1.0;
                });
              }
              _checkUrlForToken(url);
            },
            onProgressChanged: (controller, progress) {
              if (mounted) {
                setState(() {
                  _progress = progress / 100;
                });
              }
            },
            onReceivedError: (controller, request, response) {

              debugPrint(
                  "WebView onLoadError: ${request.url}, Code: ${response.type}, Message: ${response.description}");
              if (mounted) {
                setState(() {
                  _progress = 0;
                  _pageLoadingError = true;
                  _errorMessage = "Ошибка загрузки страницы (${response.type}): ${response.description}";
                });
              }
              widget.onError?.call("Load Error (${response.type}): ${response.description}");
            },
            onReceivedHttpError: (controller, request, response) {

              debugPrint(
                  "WebView onLoadHttpError: ${request.url}, Status: ${response.statusCode}, Description: ${response.reasonPhrase}");
              if (mounted) {
                setState(() {
                  _progress = 0;
                  _pageLoadingError = true;
                  _errorMessage = "HTTP Ошибка (${response.statusCode}): ${response.reasonPhrase}";
                });
              }
              widget.onError?.call("HTTP Error (${response.statusCode})");
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              debugPrint("WebView shouldOverrideUrlLoading: $uri");

              if (uri != null) {
                bool shouldCancel = _checkUrlForToken(uri);
                if (shouldCancel) {
                  return NavigationActionPolicy.CANCEL;
                }
              }
              return NavigationActionPolicy.ALLOW;
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              debugPrint("WebView onUpdateVisitedHistory: $url");
              if (url != null) {
                _checkUrlForToken(url);
              }
            },
          ),
          if (_progress < 1.0 && !_pageLoadingError)
            LinearProgressIndicator(value: _progress),
          if (_pageLoadingError && _errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _checkUrlForToken(WebUri? webUri) {
    if (webUri == null) return false;

    final String urlString = webUri.toString();
    debugPrint("WebView checking URL: $urlString");

    if (urlString.startsWith(widget.redirectUri.toString())) {
      debugPrint("WebView detected redirect URI: $urlString");
      final Uri uri = Uri.parse(urlString);

      String? potentialToken;
      String? errorMsg;
      bool foundTokenParam = false;

      if (uri.queryParameters.containsKey(tokenParamName)) {
        foundTokenParam = true;
        potentialToken = uri.queryParameters[tokenParamName];
        debugPrint("WebView found token parameter in QUERY: $potentialToken");
        if (potentialToken == null || potentialToken.isEmpty) {
          debugPrint("WebView: Token parameter in QUERY is empty.");
          errorMsg =
              "Redirect successful, but token in query parameter is missing or empty.";
        }
      } else if (uri.hasFragment && uri.fragment.isNotEmpty) {
        debugPrint("WebView checking fragment: ${uri.fragment}");
        try {
          final Map<String, String> fragmentParams =
              Uri.splitQueryString(uri.fragment);
          if (fragmentParams.containsKey(tokenParamName)) {
            foundTokenParam = true;
            potentialToken = fragmentParams[tokenParamName];
            debugPrint(
                "WebView found token parameter in FRAGMENT: $potentialToken");
            if (potentialToken == null || potentialToken.isEmpty) {
              debugPrint("WebView: Token parameter in FRAGMENT is empty.");
              errorMsg =
                  "Redirect successful, but token in fragment parameter is missing or empty.";
            }
          } else {
            debugPrint(
                "WebView: Token parameter '$tokenParamName' not found in fragment.");

            errorMsg =
                "Redirect successful, but token parameter '$tokenParamName' is missing in fragment.";
          }
        } catch (e) {
          debugPrint("WebView: Error parsing fragment: $e");
          errorMsg = "Error parsing URL fragment.";
          potentialToken = null;
        }
      }

      if (potentialToken != null && potentialToken.isNotEmpty) {
        widget.onTokenReceived(potentialToken);
        return true;
      } else {
        if (!foundTokenParam && errorMsg == null) {
          errorMsg =
              "Redirect successful, but token parameter '$tokenParamName' is missing in query and fragment.";
        }
        final finalErrorMsg = errorMsg ??
            "Redirect detected, but failed to extract a valid token.";
        debugPrint("WebView: $finalErrorMsg");
        widget.onError?.call(finalErrorMsg);
        return true;
      }
    }

    return false;
  }
}
