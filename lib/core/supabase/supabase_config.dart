/// Supabase Konfiguration
/// WICHTIG: Credentials werden via --dart-define beim Build übergeben!
///
/// Beispiel:
/// flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
///
/// Oder verwende run_dev.bat / build_release.bat
class SupabaseConfig {
  /// Supabase Project URL
  /// Format: https://[project-ref].supabase.co
  /// Zu finden unter: Settings > API > Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase Anon Key (öffentlich, sicher für Client)
  /// Zu finden unter: Settings > API > anon public
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Prüft ob Supabase konfiguriert ist
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-key';
}
