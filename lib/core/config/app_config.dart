class AppConfig {
  // MSG91 OTP Widget IDs
  // These are fetched from environment variables via --dart-define
  // Example: flutter run --dart-define=MSG91_WIDGET_ID=xxx
  
  static const String msg91WidgetCode = String.fromEnvironment(
    'MSG91_WIDGET_ID',
    defaultValue: '', // Provide this via --dart-define=MSG91_WIDGET_ID=xxx
  );

  static const String msg91AuthToken = String.fromEnvironment(
    'MSG91_AUTH_TOKEN',
    defaultValue: '', // Provide this via --dart-define=MSG91_AUTH_TOKEN=xxx
  );

  // You can add other global configuration here
}
