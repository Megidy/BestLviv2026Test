class AppApiConfig {
  const AppApiConfig._();

  static const String apiBaseUrl = 'https://best-lviv-api.example.com';
  static const String swaggerJsonUrl = '$apiBaseUrl/swagger.json';

  static const String authMePath = '/v1/auth/me';
  static const String predictiveAlertsPath = '/v1/predictive-alerts';
  static const String inventoryPath = '/v1/inventory';
  static const String mapPointsPath = '/map/points';

  static String resolve(String path) => '$apiBaseUrl$path';
}
