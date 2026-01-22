/// Supabase Konfiguration
/// WICHTIG: Diese Werte müssen nach Erstellung des Supabase-Projekts eingetragen werden!
class SupabaseConfig {
  /// Supabase Project URL
  /// Format: https://[project-ref].supabase.co
  /// Zu finden unter: Settings > API > Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kcjgnctfjodggpvqwgil.supabase.co',
  );

  /// Supabase Anon Key (öffentlich, sicher für Client)
  /// Zu finden unter: Settings > API > anon public
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjamduY3Rmam9kZ2dwdnF3Z2lsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMzcwMjcsImV4cCI6MjA4NDYxMzAyN30.GC5QdENB5APN2rKO6RtjnQqpthHd5DjN3hQnH18DGyo',
  );

  /// Prüft ob Supabase konfiguriert ist
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-key';
}
