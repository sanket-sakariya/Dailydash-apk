/// Centralized Supabase configuration.
///
/// Replace the placeholder values below with the real values from your
/// Supabase project (Project Settings → API). Treat the anon key as a public
/// key — it is safe to ship in the client because Row Level Security (RLS)
/// gates all data access on the server.
///
/// For production builds, prefer providing these via `--dart-define`, e.g.:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
///
/// and read them with `String.fromEnvironment(...)` (already wired below).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT-REF.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-SUPABASE-ANON-KEY',
  );

  /// Returns true when the values above have been overridden with a real
  /// Supabase project. Used by `main.dart` to decide whether to initialize
  /// Supabase + the auth guard, so the app stays runnable in pure-offline
  /// mode until credentials are configured.
  static bool get isConfigured =>
      !url.contains('YOUR-PROJECT-REF') &&
      anonKey != 'YOUR-SUPABASE-ANON-KEY' &&
      anonKey.isNotEmpty;
}
