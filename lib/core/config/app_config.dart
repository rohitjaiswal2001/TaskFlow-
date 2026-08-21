abstract final class AppConfig {
  static const String appName = 'TaskFlow';

  static const String mockDataAsset =
      'assets/mock_data/taskflow_mock_data.json';

  static const Duration minLatency = Duration(milliseconds: 300);
  static const Duration maxLatency = Duration(milliseconds: 800);

  static const Duration inactivityTimeout = Duration(minutes: 10);

  static const Duration tokenRefreshLeeway = Duration(seconds: 30);
}
