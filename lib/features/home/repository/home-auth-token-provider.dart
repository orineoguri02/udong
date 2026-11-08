class HomeAuthTokenProvider {
  HomeAuthTokenProvider({
    required Future<String?> Function({bool forceRefresh}) ensureToken,
    required void Function(String) log,
  }) : _ensureToken = ensureToken,
       _log = log;

  final Future<String?> Function({bool forceRefresh}) _ensureToken;
  final void Function(String) _log;

  Future<String?> ensureServerAccessToken({bool forceRefresh = false}) async {
    final token = await _ensureToken(forceRefresh: forceRefresh);
    if (token == null || token.isEmpty) {
      _log('[HomeRepo] 서버 accessToken 없음 forceRefresh=$forceRefresh');
    }
    return token;
  }
}
