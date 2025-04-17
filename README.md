# yx_auth

A cross-platform Flutter library for Yandex ID OAuth authentication. Supports Web, Android, iOS, MacOS, and Windows.

## Features
- Simple API for Yandex OAuth authorization
- All OAuth parameters are configurable
- Callback-based token delivery (no internal storage)
- Web and mobile/desktop support (via WebView)

## Getting Started
Add to your `pubspec.yaml`:
```yaml
yx_auth:
  git:
    url: https://github.com/Vvil1568/yx_auth.git
```

## Usage Example
```dart
import 'package:yx_auth/yx_auth.dart';

final yxAuth = YxAuth(
  clientId: 'your-client-id',
  redirectUri: 'https://your-redirect-uri',
  domain: 'oauth.yandex.ru',
  origin: 'your-origin',
  state: 'your-state',
  onTokenReceived: (token) {
    // Handle the received token
    print('Received token: $token');
  },
);

// For Web: call this at app startup (e.g. in main() or initState)
yxAuth.handleRedirectOnWebIfPresent();

// For all platforms: call signIn() on button press
await yxAuth.signIn(context: context);
```

## Example
See [`example/main.dart`](example/main.dart) for a complete usage example with real parameters.

## Platform Notes
- **Web:**
  - Call `handleRedirectOnWebIfPresent()` at app startup (e.g. in main() or initState of your main widget).
  - This will automatically catch the token in the URL if the user was redirected back after authentication.
  - Call `signIn()` only to initiate the login redirect.
- **Mobile/Desktop:** Uses [flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview) to open the OAuth page and extract the token from the redirect URI fragment.

## API
### YxAuth
| Parameter         | Description                        |
|-------------------|------------------------------------|
| `clientId`        | Your Yandex OAuth application ID    |
| `redirectUri`     | Redirect URI registered in Yandex   |
| `domain`          | OAuth domain (usually oauth.yandex.ru) |
| `origin`          | Origin string for your app          |
| `state`           | OAuth state parameter               |
| `onTokenReceived` | Callback for receiving the token    |

### Methods
- `Future<void> signIn({BuildContext? context})` — Starts the authentication flow.
- `void handleRedirectOnWebIfPresent()` — Checks the URL for a token and calls the callback if found (Web only).
- `String buildAuthUrl()` — Returns the OAuth URL.

## License
MIT
