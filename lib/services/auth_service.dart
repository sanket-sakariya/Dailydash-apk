import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Centralized authentication service.
///
/// Uses Supabase's built-in email/password auth (`signInWithPassword` and
/// `signUp`). Exposes a reactive [currentUserNotifier] and [authStateChanges]
/// stream so the UI can react without depending on `supabase_flutter`
/// directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ValueNotifier<User?> currentUserNotifier = ValueNotifier<User?>(null);

  bool _initialized = false;

  /// Wires up the auth state listener. Call once after [SupabaseService]
  /// has been initialized.
  void initialize() {
    if (_initialized) return;
    if (!SupabaseService.instance.isReady) return;
    _initialized = true;

    currentUserNotifier.value = SupabaseService.instance.currentUser;
    SupabaseService.instance.auth.onAuthStateChange.listen((event) {
      currentUserNotifier.value = event.session?.user;
    });
  }

  /// Reactive stream of the underlying auth state for advanced consumers.
  Stream<AuthState> get authStateChanges =>
      SupabaseService.instance.auth.onAuthStateChange;

  User? get currentUser => SupabaseService.instance.currentUser;

  bool get isSignedIn => currentUser != null;

  void _ensureConfigured() {
    if (!SupabaseService.instance.isReady) {
      throw const AuthException(
        'Supabase is not configured. Set SUPABASE_URL / SUPABASE_ANON_KEY '
        'in lib/config/supabase_config.dart (or via --dart-define).',
      );
    }
  }

  /// Email + password sign-in. Throws [AuthException] on failure.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    return await SupabaseService.instance.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Email + password sign-up.
  ///
  /// If email confirmation is enabled in the Supabase project, the returned
  /// [AuthResponse] will have a `null` session and the user must confirm via
  /// the email link before they can sign in. If confirmation is disabled, a
  /// session is returned immediately.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _ensureConfigured();
    return await SupabaseService.instance.auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null && displayName.trim().isNotEmpty
          ? {'display_name': displayName.trim()}
          : null,
    );
  }

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordReset(String email) async {
    _ensureConfigured();
    await SupabaseService.instance.auth.resetPasswordForEmail(email.trim());
  }

  /// Signs out of Supabase and wipes the local SQLite cache so the next user
  /// does not inherit the previous user's data.
  Future<void> signOut() async {
    if (SupabaseService.instance.isReady) {
      await SupabaseService.instance.auth.signOut();
    }

    try {
      await DatabaseHelper.instance.clearAll();
    } catch (_) {
      // Non-fatal — the DB may not be open on web.
    }
  }
}
