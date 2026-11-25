class AdminConfig {
  AdminConfig._();

  /// Dedicated administrator email. All other accounts are treated as customers (`Client`).
  static const String adminEmail = 'phanviettinh150402@gmail.com';

  /// Default hosted URL for the Flutter Web Admin portal (Firebase Hosting free domain).
  static const String adminWebUrl = String.fromEnvironment(
    'ADMIN_WEB_URL',
    defaultValue: 'https://fashion-business-app.web.app',
  );

  static String normalizeEmail(String? email) => (email ?? '').trim().toLowerCase();

  static bool isAdminEmail(String? email) => normalizeEmail(email) == adminEmail;

  static String roleForEmail(String? email) => isAdminEmail(email) ? 'Admin' : 'Client';
}
