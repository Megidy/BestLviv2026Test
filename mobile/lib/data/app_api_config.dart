class AppApiConfig {
  const AppApiConfig._();

  static const bool _isReleaseBuild = bool.fromEnvironment('dart.vm.product');

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'LOGISYNC_API_BASE_URL',
    defaultValue: 'https://api.logisync.systems',
  );
  static const bool _allowInsecureHttp = bool.fromEnvironment(
    'LOGISYNC_ALLOW_INSECURE_HTTP',
    // Debug/profile builds allow HTTP by default to simplify local/dev runs.
    // Release builds keep HTTPS-only unless explicitly overridden.
    defaultValue: !_isReleaseBuild,
  );
  static final String apiBaseUrl = _resolveBaseUrl();

  static const String authLoginPath = '/v1/auth/login';
  static const String authMePath = '/v1/auth/me';
  static const String predictiveAlertsPath = '/v1/predictive-alerts';
  static const String demandReadingsPath = '/v1/demand-readings';
  static const String deliveryRequestsPath = '/v1/delivery-requests';
  static const String stockNearestPath = '/v1/stock/nearest';
  static const String rebalancingProposalsPath =
      '/v1/rebalancing-proposals';
  static const String inventoryPath = '/v1/inventory';
  static const String mapPointsPath = '/v1/map/points';
  static const String allocationsPath = '/v1/allocations';

  static String _resolveBaseUrl() {
    final configured = _rawApiBaseUrl.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.tryParse(configured);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw StateError(
        'Invalid LOGISYNC_API_BASE_URL: "$configured". '
        'Expected absolute URL, for example https://api.example.com',
      );
    }

    if (uri.scheme != 'https' && !_allowInsecureHttp) {
      throw StateError(
        'Insecure API URL is blocked: "$configured". '
        'Use HTTPS or set --dart-define=LOGISYNC_ALLOW_INSECURE_HTTP=true for local dev only.',
      );
    }

    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }

  static String resolve(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }
}
