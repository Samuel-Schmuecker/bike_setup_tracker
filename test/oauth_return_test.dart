import 'dart:convert';
import 'dart:io';
import 'package:bike_setup_tracker/cloud/oauth_return_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'desktop callback rejects wrong attempt and never reflects credentials',
    () async {
      Uri? received;
      final listener = await OAuthReturn.open(
        'test-attempt',
        (uri) async {
          received = uri;
        },
        port: 0,
        languageCode: 'en',
      );
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await listener.close();
      });
      final redirect = Uri.parse(listener.redirect);
      final wrong = await (await client.getUrl(
        redirect.replace(query: 'attempt=wrong&code=secret'),
      )).close();
      expect(wrong.statusCode, 404);
      await wrong.drain<void>();
      expect(received, isNull);
      final correct = await (await client.getUrl(
        redirect.replace(query: 'attempt=test-attempt&code=secret'),
      )).close();
      final page = await utf8.decoder.bind(correct).join();
      expect(correct.statusCode, 200);
      expect(received!.queryParameters['code'], 'secret');
      expect(page, isNot(contains('secret')));
      expect(page, contains('Sign-in processed'));
      expect(
        page,
        contains('You can close this window and return to the app.'),
      );
    },
  );
}
