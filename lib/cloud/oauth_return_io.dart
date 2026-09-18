import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../utils/translations.dart';

/// Mobile returns through app_links. Desktop uses a short-lived loopback listener.
class OAuthReturn {
  OAuthReturn._(this.redirect, [this._server]);
  final String redirect;
  final HttpServer? _server;
  Timer? _timeout;

  static Future<OAuthReturn> open(
    String attempt,
    Future<void> Function(Uri) onReturn, {
    int port = 43827,
    String languageCode = 'de',
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return OAuthReturn._('bikesetuptracker://auth/callback');
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final result = OAuthReturn._(
      'http://127.0.0.1:${server.port}/auth/callback?attempt=$attempt',
      server,
    );
    result._timeout = Timer(const Duration(minutes: 15), result.close);
    server.listen((request) async {
      if (request.method != 'GET' ||
          request.uri.path != '/auth/callback' ||
          request.uri.queryParameters['attempt'] != attempt) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      request.response.headers.contentType = ContentType.html;
      request.response.headers.set('Cache-Control', 'no-store');
      request.response.headers.set('Referrer-Policy', 'no-referrer');
      try {
        await onReturn(
          Uri.parse(result.redirect).replace(query: request.uri.query),
        );
        request.response.write(
          '<!doctype html><meta charset="utf-8"><title>Bike Setup Tracker</title>'
          '<h1>${const HtmlEscape().convert(Translations.get(languageCode, 'authReturnSuccessTitle'))}</h1>'
          '<p>${const HtmlEscape().convert(Translations.get(languageCode, 'authReturnSuccessBody'))}</p>',
        );
      } catch (_) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(
          '<!doctype html><meta charset="utf-8"><title>Bike Setup Tracker</title>'
          '<h1>${const HtmlEscape().convert(Translations.get(languageCode, 'authReturnErrorTitle'))}</h1>'
          '<p>${const HtmlEscape().convert(Translations.get(languageCode, 'authReturnErrorBody'))}</p>',
        );
      } finally {
        await request.response.close();
        await result.close();
      }
    });
    return result;
  }

  Future<void> close() async {
    _timeout?.cancel();
    await _server?.close(force: true);
  }
}
