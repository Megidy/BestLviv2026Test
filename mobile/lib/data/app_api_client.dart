import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_api_config.dart';
import 'auth_token_store.dart';

class AppApiClient {
  AppApiClient({
    http.Client? httpClient,
    AuthTokenStore? tokenStore,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStore = tokenStore ?? AuthTokenStore();

  final http.Client _httpClient;
  final AuthTokenStore _tokenStore;

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

  Future<void> clearToken() => _tokenStore.clear();

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? queryParameters,
    Object? body,
    required bool authorized,
  }) async {
    final uri = Uri.parse(
      AppApiConfig.resolve(path),
    ).replace(
      queryParameters: _normalizeQuery(queryParameters),
    );

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (authorized) {
      final token = await _tokenStore.read();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Missing access token. Please sign in again.',
          isUnauthorized: true,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

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
      throw const ApiException(
        message: 'Request timed out. Please retry.',
        errorType: ApiErrorType.timeout,
      );
    } on SocketException {
      throw const ApiException(
        message: 'Network error. Check your connection and try again.',
        errorType: ApiErrorType.network,
      );
    }

    return _decodeResponse(response);
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
