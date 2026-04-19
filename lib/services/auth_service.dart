import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show repo, usernameNotifier, avatarNotifier, budgetNotifier, currencyNotifier;
import 'sync_service.dart';
import 'profile_service.dart';

/// Application authentication states (prefixed to avoid conflict with Supabase AuthState)
enum AppAuthState {
  /// Initial state, checking for existing session
  unknown,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,
}

/// Service for managing Supabase authentication
///
/// Uses ValueNotifier for reactive state management consistent with
/// the app's existing architecture.
class AuthService {
  static final AuthService instance = AuthService._init();

  final _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  /// Current authenticated user
  final currentUserNotifier = ValueNotifier<User?>(null);

  /// Current authentication state
  final authStateNotifier = ValueNotifier<AppAuthState>(AppAuthState.unknown);

  /// Loading state for auth operations
  final isLoadingNotifier = ValueNotifier<bool>(false);

  /// Error message from last operation
  final errorNotifier = ValueNotifier<String?>(null);

  AuthService._init();

  /// Get current user ID or null if not authenticated
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Get current user email or null if not authenticated
  String? get currentUserEmail => _supabase.auth.currentUser?.email;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUserId != null;

  /// Initialize the auth service and listen to auth state changes
  void initialize() {
    // Check for existing session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      currentUserNotifier.value = _supabase.auth.currentUser;
      authStateNotifier.value = AppAuthState.authenticated;
    } else {
      authStateNotifier.value = AppAuthState.unauthenticated;
    }

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          currentUserNotifier.value = session?.user;
          authStateNotifier.value = AppAuthState.authenticated;
          _onSignedIn();
          break;
        case AuthChangeEvent.signedOut:
          currentUserNotifier.value = null;
          authStateNotifier.value = AppAuthState.unauthenticated;
          break;
        case AuthChangeEvent.initialSession:
          if (session != null) {
            currentUserNotifier.value = session.user;
            authStateNotifier.value = AppAuthState.authenticated;
          } else {
            authStateNotifier.value = AppAuthState.unauthenticated;
          }
          break;
        default:
          break;
      }
    });
  }

  /// Called after successful sign in
  Future<void> _onSignedIn() async {
    final userId = currentUserId;
    if (userId == null) return;

    // Delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Assign any orphaned local expenses to this user
      await repo.assignUserIdToOrphans(userId);
    } catch (e) {
      debugPrint('Error assigning orphans: $e');
    }

    try {
      // Trigger a full sync to pull any existing cloud data
      await SyncService.instance.fullSync();
    } catch (e) {
      debugPrint('Error during sync: $e');
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        currentUserNotifier.value = response.user;
        authStateNotifier.value = AppAuthState.authenticated;
      }

      return response;
    } on AuthException catch (e) {
      errorNotifier.value = e.message;
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      currentUserNotifier.value = response.user;
      authStateNotifier.value = AppAuthState.authenticated;

      return response;
    } on AuthException catch (e) {
      errorNotifier.value = e.message;
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Sign out and clear local data
  ///
  /// IMPORTANT: Clears local SQLite data BEFORE signing out
  /// to prevent data leakage between users.
  Future<void> signOut() async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      // CRITICAL: Clear local data first to prevent data leakage
      await repo.clearAllData();

      // Clear profile cache and notifiers
      await ProfileService.instance.clearProfile();
      usernameNotifier.clear();
      avatarNotifier.clear();
      budgetNotifier.clear();
      currencyNotifier.clear();

      // Stop sync service
      SyncService.instance.dispose();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      currentUserNotifier.value = null;
      authStateNotifier.value = AppAuthState.unauthenticated;
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      errorNotifier.value = e.message;
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Send OTP to email for signup verification
  Future<void> sendSignUpOtp({required String email}) async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      // Use signInWithOtp to send OTP - this creates user if doesn't exist
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
    } on AuthException catch (e) {
      errorNotifier.value = e.message;
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Sign up with email, password, and OTP verification
  Future<AuthResponse> signUpWithOtp({
    required String email,
    required String password,
    required String otp,
  }) async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      // Verify the OTP - this signs in the user
      final verifyResponse = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (verifyResponse.user == null || verifyResponse.session == null) {
        throw const AuthException('Invalid OTP code');
      }

      // OTP verified and user is signed in, now set the password
      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      currentUserNotifier.value = verifyResponse.user;
      authStateNotifier.value = AppAuthState.authenticated;

      return verifyResponse;
    } on AuthException catch (e) {
      errorNotifier.value = e.message;
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Delete user account permanently
  ///
  /// This will:
  /// 1. Delete all user data from Supabase
  /// 2. Clear local data
  /// 3. Sign out
  Future<void> deleteAccount() async {
    errorNotifier.value = null;
    isLoadingNotifier.value = true;

    try {
      final userId = currentUserId;
      if (userId == null) {
        throw const AuthException('No user signed in');
      }

      // Delete user's expenses from Supabase
      await _supabase.from('expenses').delete().eq('user_id', userId);

      // Delete user's profile from Supabase
      await _supabase.from('user_profiles').delete().eq('id', userId);

      // Clear local data
      await repo.clearAllData();

      // Clear profile cache and notifiers
      await ProfileService.instance.clearProfile();
      usernameNotifier.clear();
      avatarNotifier.clear();
      budgetNotifier.clear();
      currencyNotifier.clear();

      // Stop sync service
      SyncService.instance.dispose();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      currentUserNotifier.value = null;
      authStateNotifier.value = AppAuthState.unauthenticated;
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    currentUserNotifier.dispose();
    authStateNotifier.dispose();
    isLoadingNotifier.dispose();
    errorNotifier.dispose();
  }
}
