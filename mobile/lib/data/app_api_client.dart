import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'app_api_config.dart';
import 'auth_token_store.dart';

class AppApiClient {
  static const String _getCachePrefix = 'logisync.get_cache.v1.';
  static const String _mutationQueueStorageKey =
      'logisync.mutation_queue.v1';

  AppApiClient({
    http.Client? httpClient,
    AuthTokenStore? tokenStore,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStore = tokenStore ?? AuthTokenStore() {
    unawaited(_initializeQueueState());
  }

  final http.Client _httpClient;
  final AuthTokenStore _tokenStore;
  final ValueNotifier<bool> _isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<int> _pendingMutationCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isSyncingQueue = ValueNotifier<bool>(false);

  ValueListenable<bool> get isOnlineListenable => _isOnline;
  ValueListenable<int> get pendingMutationCountListenable =>
      _pendingMutationCount;
  ValueListenable<bool> get isSyncingQueueListenable => _isSyncingQueue;

  Future<dynamic> get(
    String path, {
    Map<String, Object?>? queryParameters,
    bool authorized = true,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
      authorized: authorized,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, Object?>? queryParameters,
    Object? body,
    bool authorized = true,
  }) {
    return _send(
      'POST',
      path,
      queryParameters: queryParameters,
      body: body,
      authorized: authorized,
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, Object?>? queryParameters,
    Object? body,
    bool authorized = true,
  }) {
    return _send(
      'PATCH',
      path,
      queryParameters: queryParameters,
      body: body,
      authorized: authorized,
    );
  }

  Future<void> saveToken(String token) => _tokenStore.save(token);

  Future<String?> readToken() => _tokenStore.read();

  Future<void> clearToken() async {
    await _tokenStore.clear();
    await _clearMutationQueue();
  }

  Future<int> processPendingMutations() async {
    if (_isSyncingQueue.value) {
      return 0;
    }

    _isSyncingQueue.value = true;
    try {
      var queue = await _readMutationQueue();
      if (queue.isEmpty) {
        _pendingMutationCount.value = 0;
        return 0;
      }

      var applied = 0;
      while (queue.isNotEmpty) {
        final action = queue.first;
        try {
          await _send(
            action.method,
            action.path,
            queryParameters: action.queryParameters,
            body: action.body,
            authorized: action.authorized,
            allowQueueOnFailure: false,
          );

          queue = queue.sublist(1);
          applied += 1;
          await _writeMutationQueue(queue);
          _pendingMutationCount.value = queue.length;
        } on ApiException catch (error) {
          if (error.isNetworkError || error.isTimeout || error.isServerError) {
            _setOnline(false);
            break;
          }

          if (error.isUnauthorized) {
            break;
          }

          queue = queue.sublist(1);
          await _writeMutationQueue(queue);
          _pendingMutationCount.value = queue.length;
        }
      }

      return applied;
    } finally {
      _isSyncingQueue.value = false;
    }
  }

  Future<void> _initializeQueueState() async {
    final queue = await _readMutationQueue();
    _pendingMutationCount.value = queue.length;
    if (_isOnline.value && queue.isNotEmpty) {
      unawaited(processPendingMutations());
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? queryParameters,
    Object? body,
    required bool authorized,
    bool allowQueueOnFailure = true,
  }) async {
    final uri = Uri.parse(
      AppApiConfig.resolve(path),
    ).replace(
      queryParameters: _normalizeQuery(queryParameters),
    );
    final isGetRequest = method == 'GET';

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    String? token;
    if (authorized) {
      token = await _tokenStore.read();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Missing access token. Please sign in again.',
          isUnauthorized: true,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final cacheScope = _cacheScopeForRequest(
      authorized: authorized,
      token: token,
    );
    final cacheKey = isGetRequest
        ? _buildGetCacheKey(uri: uri, cacheScope: cacheScope)
        : null;

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await _httpClient
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 20));
          break;
        default:
          throw ApiException(message: 'Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      final cached = await _readCachedGetResponse(cacheKey);
      if (cached != null) {
        _setOnline(false);
        return cached;
      }

      if (allowQueueOnFailure && _isMutationMethod(method)) {
        await _enqueueMutation(
          method: method,
          path: path,
          queryParameters: queryParameters,
          body: body,
          authorized: authorized,
        );
        _setOnline(false);
        throw const ApiException(
          message:
              'No connection. Action queued and will be applied automatically when internet is restored.',
          errorType: ApiErrorType.queued,
        );
      }

      _setOnline(false);
      throw const ApiException(
        message: 'Request timed out. Please retry.',
        errorType: ApiErrorType.timeout,
      );
    } on SocketException {
      final cached = await _readCachedGetResponse(cacheKey);
      if (cached != null) {
        _setOnline(false);
        return cached;
      }

      if (allowQueueOnFailure && _isMutationMethod(method)) {
        await _enqueueMutation(
          method: method,
          path: path,
          queryParameters: queryParameters,
          body: body,
          authorized: authorized,
        );
        _setOnline(false);
        throw const ApiException(
          message:
              'No connection. Action queued and will be applied automatically when internet is restored.',
          errorType: ApiErrorType.queued,
        );
      }

      _setOnline(false);
      throw const ApiException(
        message: 'Network error. Check your connection and try again.',
        errorType: ApiErrorType.network,
      );
    }

    _setOnline(true);
    final decoded = _decodeResponse(response);
    if (isGetRequest) {
      await _writeCachedGetResponse(
        cacheKey: cacheKey,
        data: decoded,
      );
    }
    return decoded;
  }

  void _setOnline(bool value) {
    final changed = _isOnline.value != value;
    if (changed) {
      _isOnline.value = value;
    }

    if (value &&
        _pendingMutationCount.value > 0 &&
        !_isSyncingQueue.value) {
      unawaited(processPendingMutations());
    }
  }

  bool _isMutationMethod(String method) {
    return method == 'POST' || method == 'PATCH';
  }

  String _cacheScopeForRequest({
    required bool authorized,
    required String? token,
  }) {
    if (!authorized) {
      return 'public';
    }

    if (token == null || token.isEmpty) {
      return 'auth_anonymous';
    }

    return 'auth_${_stableFingerprint(token)}';
  }

  String _buildGetCacheKey({
    required Uri uri,
    required String cacheScope,
  }) {
    return '$_getCachePrefix$cacheScope|${uri.toString()}';
  }

  String _stableFingerprint(String raw) {
    var hash = 0x811C9DC5;
    for (final unit in raw.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<dynamic> _readCachedGetResponse(String? cacheKey) async {
    if (cacheKey == null || cacheKey.isEmpty) {
      return null;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(cacheKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedGetResponse({
    required String? cacheKey,
    required dynamic data,
  }) async {
    if (cacheKey == null || cacheKey.isEmpty) {
      return;
    }

    try {
      final payload = jsonEncode(<String, Object?>{
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      });

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(cacheKey, payload);
    } catch (_) {
      // Ignore cache serialization/storage failures and continue with network data.
    }
  }

  Future<void> _enqueueMutation({
    required String method,
    required String path,
    required Map<String, Object?>? queryParameters,
    required Object? body,
    required bool authorized,
  }) async {
    final queue = await _readMutationQueue();
    queue.add(
      _QueuedMutation(
        method: method,
        path: path,
        queryParameters: queryParameters == null
            ? null
            : Map<String, Object?>.from(queryParameters),
        body: body,
        authorized: authorized,
        queuedAt: DateTime.now().toUtc(),
      ),
    );

    await _writeMutationQueue(queue);
    _pendingMutationCount.value = queue.length;
  }

  Future<List<_QueuedMutation>> _readMutationQueue() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_mutationQueueStorageKey);
      if (raw == null || raw.trim().isEmpty) {
        return <_QueuedMutation>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <_QueuedMutation>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) => _QueuedMutation.fromJson(
              entry.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .toList();
    } catch (_) {
      return <_QueuedMutation>[];
    }
  }

  Future<void> _writeMutationQueue(List<_QueuedMutation> queue) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (queue.isEmpty) {
        await preferences.remove(_mutationQueueStorageKey);
        return;
      }

      final payload = jsonEncode(
        queue.map((item) => item.toJson()).toList(growable: false),
      );
      await preferences.setString(_mutationQueueStorageKey, payload);
    } catch (_) {
      // Ignore queue storage failures to keep runtime flow non-blocking.
    }
  }

  Future<void> _clearMutationQueue() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_mutationQueueStorageKey);
    } catch (_) {
      // Ignore queue cleanup failures.
    }
    _pendingMutationCount.value = 0;
  }

  Map<String, String>? _normalizeQuery(Map<String, Object?>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return null;
    }

    final normalized = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      normalized[entry.key] = value.toString();
    }
    return normalized.isEmpty ? null : normalized;
  }

  dynamic _decodeResponse(http.Response response) {
    dynamic decodedBody;
    if (response.bodyBytes.isNotEmpty) {
      final text = utf8.decode(response.bodyBytes);
      if (text.trim().isNotEmpty) {
        try {
          decodedBody = jsonDecode(text);
        } on FormatException {
          decodedBody = text;
        }
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final metadata = _extractMetadata(decodedBody);
      final errorType = _errorTypeForStatus(response.statusCode);
      final message =
          _firstString([
            metadata['message'],
            metadata['error'],
          ]) ??
          _defaultMessageForStatus(response.statusCode);
      throw ApiException(
        message: message,
        statusCode: response.statusCode,
        isUnauthorized: response.statusCode == 401,
        errorType: errorType,
      );
    }

    return _extractData(decodedBody);
  }

  dynamic _extractData(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      if (decodedBody.containsKey('data')) {
        return decodedBody['data'];
      }
      if (decodedBody.containsKey('Data')) {
        return decodedBody['Data'];
      }
    }
    return decodedBody;
  }

  Map<String, dynamic> _extractMetadata(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      final metadata = decodedBody['metadata'];
      if (metadata is Map<String, dynamic>) {
        return metadata;
      }
      if (metadata is Map) {
        return metadata.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }
    return const <String, dynamic>{};
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  ApiErrorType _errorTypeForStatus(int statusCode) {
    if (statusCode == 401) {
      return ApiErrorType.unauthorized;
    }
    if (statusCode == 403) {
      return ApiErrorType.forbidden;
    }
    if (statusCode == 404) {
      return ApiErrorType.notFound;
    }
    if (statusCode >= 500) {
      return ApiErrorType.server;
    }
    return ApiErrorType.unknown;
  }

  String _defaultMessageForStatus(int statusCode) {
    return switch (_errorTypeForStatus(statusCode)) {
      ApiErrorType.unauthorized =>
        'Session is invalid or expired. Please sign in again.',
      ApiErrorType.forbidden =>
        'You do not have permission to perform this action.',
      ApiErrorType.notFound => 'Requested data was not found.',
      ApiErrorType.server =>
        'Server error occurred. Please retry in a moment.',
      _ => 'Request failed with status $statusCode.',
    };
  }
}

class _QueuedMutation {
  const _QueuedMutation({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.body,
    required this.authorized,
    required this.queuedAt,
  });

  final String method;
  final String path;
  final Map<String, Object?>? queryParameters;
  final Object? body;
  final bool authorized;
  final DateTime queuedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'method': method,
      'path': path,
      'queryParameters': queryParameters,
      'body': body,
      'authorized': authorized,
      'queuedAt': queuedAt.toIso8601String(),
    };
  }

  factory _QueuedMutation.fromJson(Map<String, dynamic> map) {
    final rawQuery = map['queryParameters'];
    Map<String, Object?>? query;
    if (rawQuery is Map) {
      query = rawQuery.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    final queuedAtRaw = map['queuedAt'];
    final queuedAt = queuedAtRaw is String
        ? DateTime.tryParse(queuedAtRaw)
        : null;

    return _QueuedMutation(
      method: map['method']?.toString() ?? 'POST',
      path: map['path']?.toString() ?? '',
      queryParameters: query,
      body: map['body'],
      authorized: map['authorized'] == true,
      queuedAt: queuedAt ?? DateTime.now().toUtc(),
    );
  }
}
