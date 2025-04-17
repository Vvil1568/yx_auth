import 'package:flutter/material.dart';
import 'package:yx_auth/yx_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YX Auth Example',
      home: const AuthExampleScreen(),
    );
  }
}

class AuthExampleScreen extends StatefulWidget {
  const AuthExampleScreen({super.key});

  @override
  State<AuthExampleScreen> createState() => _AuthExampleScreenState();
}

class _AuthExampleScreenState extends State<AuthExampleScreen> {
  String? _token;

  // Example parameters for Yandex OAuth
  static const String clientId = 'bcc75242b623416cb7e4068ad50ac408';
  static const String redirectUri = 'http://localhost:8000/callback';
  static const String domain = 'oauth.yandex.ru';
  static const String origin = 'yandex_auth_sdk_android_v3';
  static const String state = 'test';

  late final YxAuth _auth;

  @override
  void initState() {
    super.initState();
    _auth = YxAuth(
      clientId: clientId,
      redirectUri: redirectUri,
      domain: domain,
      origin: origin,
      state: state,
      onTokenReceived: (token) {
        setState(() => _token = token);
      },
    );
    // For Web: automatically catch token if present in URL
    _auth.handleRedirectOnWebIfPresent();
  }

  Future<void> _signIn() async {
    await _auth.signIn(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YX Auth Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_token != null)
              Text('Token: $_token')
            else
              const Text('Not signed in'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
