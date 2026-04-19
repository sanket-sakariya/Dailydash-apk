import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin singleton wrapper around the [Supabase] global client.
///
/// Centralizing access here avoids leaking the `supabase_flutter` import into
/// every layer of the app and makes it trivial to mock in tests.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  /// Idempotent — safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!SupabaseConfig.isConfigured) {
      // Operate in "offline-only" mode if the developer has not yet provided
      // real credentials. The rest of the app degrades gracefully.
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      // The default `pkce` flow works for OAuth deep-link redirects on mobile.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  bool get isReady => _initialized;

  SupabaseClient get client => Supabase.instance.client;

  GoTrueClient get auth => client.auth;

  /// Convenience accessor for the `expenses` table.
  SupabaseQueryBuilder get expenses => client.from('expenses');

  /// Currently signed-in user, or null when signed out / not configured.
  User? get currentUser {
    if (!_initialized) return null;
    return auth.currentUser;
  }
}
