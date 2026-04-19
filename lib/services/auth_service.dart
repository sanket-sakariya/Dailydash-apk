import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Centralized authentication service.
///
/// Wraps Google Sign-In and forwards the returned `idToken` to Supabase via
/// `signInWithIdToken`. Exposes a reactive [authStateChanges] stream and a
/// [currentUserNotifier] that the UI can listen to without depending on the
/// `supabase_flutter` package directly.
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

  /// Native Google Sign-In → Supabase ID-token exchange.
  ///
  /// Throws a descriptive [AuthException] on failure so the UI can surface a
  /// human-readable error message.
  Future<AuthResponse> signInWithGoogle() async {
    if (!SupabaseService.instance.isReady) {
      throw const AuthException(
        'Supabase is not configured. Set SUPABASE_URL / SUPABASE_ANON_KEY '
        'in lib/config/supabase_config.dart (or via --dart-define).',
      );
    }

    final googleSignIn = GoogleSignIn(
      // On Android the client id is read from `google-services.json`. On iOS
      // and web it must be supplied explicitly.
      clientId: SupabaseConfig.googleIosClientId.isNotEmpty
          ? SupabaseConfig.googleIosClientId
          : null,
      serverClientId: SupabaseConfig.googleWebClientId.isNotEmpty
          ? SupabaseConfig.googleWebClientId
          : null,
      scopes: const ['email', 'profile', 'openid'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException(
        'Google sign-in did not return an ID token. Verify the OAuth client '
        'configuration in the Google Cloud console.',
      );
    }

    return await SupabaseService.instance.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Signs out of Supabase, revokes the local Google session, and wipes the
  /// SQLite cache so the next user does not inherit the previous user's data.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Non-fatal: the Google SDK may not be initialized.
    }

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
