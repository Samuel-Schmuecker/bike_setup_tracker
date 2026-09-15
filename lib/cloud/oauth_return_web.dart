class OAuthReturn {
  OAuthReturn._(this.redirect);
  final String redirect;
  static Future<OAuthReturn> open(
    String attempt,
    Future<void> Function(Uri) onReturn,
  ) async =>
      OAuthReturn._(Uri.base.replace(query: '', fragment: '').toString());
  Future<void> close() async {}
}
