enum ApiErrorType {
  unauthorized,
  forbidden,
  notFound,
  server,
  timeout,
  network,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.isUnauthorized = false,
    this.errorType = ApiErrorType.unknown,
  });

  final String message;
  final int? statusCode;
  final bool isUnauthorized;
  final ApiErrorType errorType;

  bool get isForbidden => errorType == ApiErrorType.forbidden;
  bool get isNotFound => errorType == ApiErrorType.notFound;
  bool get isServerError => errorType == ApiErrorType.server;
  bool get isTimeout => errorType == ApiErrorType.timeout;
  bool get isNetworkError => errorType == ApiErrorType.network;

  @override
  String toString() => message;
}
