import 'package:flutter_test/flutter_test.dart';
import 'package:yx_auth/yx_auth.dart';

void main() {
  group('YxAuth', () {
    test('builds correct auth URL', () async {
      final auth = YxAuth(
        clientId: 'id',
        redirectUri: 'http://localhost',
        domain: 'oauth.yandex.ru',
        origin: 'origin',
        state: 'state',
        onTokenReceived: (_) {},
      );
      final url = auth.buildAuthUrl();
      expect(url, contains('client_id=id'));
      expect(url, contains('redirect_uri=http://localhost'));
      expect(url, contains('origin=origin'));
      expect(url, contains('state=state'));
      expect(url, contains('https://oauth.yandex.ru/authorize'));
    });

    test('calls onTokenReceived callback', () async {
      String? receivedToken;
      final auth = YxAuth(
        clientId: 'id',
        redirectUri: 'http://localhost',
        domain: 'oauth.yandex.ru',
        origin: 'origin',
        state: 'state',
        onTokenReceived: (token) {
          receivedToken = token;
        },
      );
      // Simulate receiving a token
      auth.onTokenReceived('test_token');
      expect(receivedToken, equals('test_token'));
    });
  });
}
