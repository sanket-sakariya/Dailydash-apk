import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Avatar types available for user profile
enum AvatarType {
  male,
  female,
  neutral, // This is "other" - shows blank/neutral avatar
}

/// User profile data model
class UserProfile {
  final String id;
  final String displayName;
  final AvatarType avatarType;
  final double monthlyBudget;
  final String currency;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.avatarType,
    required this.monthlyBudget,
    required this.currency,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'User',
      avatarType: _parseAvatarType(json['avatar_type'] as String?),
      monthlyBudget: (json['monthly_budget'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_type': avatarType.name,
      'monthly_budget': monthlyBudget,
      'currency': currency,
    };
  }

  UserProfile copyWith({
    String? displayName,
    AvatarType? avatarType,
    double? monthlyBudget,
    String? currency,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarType: avatarType ?? this.avatarType,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
    );
  }

  static AvatarType _parseAvatarType(String? type) {
    switch (type) {
      case 'female':
        return AvatarType.female;
      case 'neutral':
        return AvatarType.neutral;
      case 'male':
      default:
        return AvatarType.male;
    }
  }
}

/// Service for managing user profile data in Supabase
class ProfileService {
  static final ProfileService instance = ProfileService._init();

  final _supabase = Supabase.instance.client;

  /// Current user profile
  final profileNotifier = ValueNotifier<UserProfile?>(null);

  /// Loading state
  final isLoadingNotifier = ValueNotifier<bool>(false);

  ProfileService._init();

  /// Load profile from Supabase (call this on login)
  Future<void> loadProfile() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      debugPrint('ProfileService: No user ID, cannot load profile');
      return;
    }

    isLoadingNotifier.value = true;
    debugPrint('ProfileService: Loading profile for user $userId');

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('ProfileService: Found existing profile');
        profileNotifier.value = UserProfile.fromJson(response);
      } else {
        debugPrint('ProfileService: No profile found, creating new one');
        await _createProfile(userId);
      }
    } catch (e) {
      debugPrint('ProfileService: Error loading profile: $e');
      // Create a default local profile
      profileNotifier.value = UserProfile(
        id: userId,
        displayName: 'User',
        avatarType: AvatarType.male,
        monthlyBudget: 0,
        currency: 'INR',
      );
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Create initial profile for new user
  Future<void> _createProfile(String userId) async {
    final profile = UserProfile(
      id: userId,
      displayName: 'User',
      avatarType: AvatarType.male,
      monthlyBudget: 0,
      currency: 'INR',
    );

    try {
      // Use upsert to handle both insert and update
      await _supabase.from('user_profiles').upsert(profile.toJson());
      profileNotifier.value = profile;
      debugPrint('ProfileService: Created new profile');
    } catch (e) {
      debugPrint('ProfileService: Error creating profile: $e');
      // Still set local profile so app can function
      profileNotifier.value = profile;
    }
  }

  /// Update display name in Supabase
  Future<void> updateDisplayName(String name) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    debugPrint('ProfileService: Updating display name to "$name"');

    // Update local state immediately
    final currentProfile = profileNotifier.value;
    final updatedProfile =
        currentProfile?.copyWith(displayName: name) ??
        UserProfile(
          id: userId,
          displayName: name,
          avatarType: AvatarType.male,
          monthlyBudget: 0,
          currency: 'INR',
        );
    profileNotifier.value = updatedProfile;

    // Sync to Supabase
    try {
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'display_name': name,
      });
      debugPrint('ProfileService: Display name updated in Supabase');
    } catch (e) {
      debugPrint('ProfileService: Error updating display name: $e');
    }
  }

  /// Update avatar type in Supabase
  Future<void> updateAvatarType(AvatarType type) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    debugPrint('ProfileService: Updating avatar to "${type.name}"');

    // Update local state immediately
    final currentProfile = profileNotifier.value;
    final updatedProfile =
        currentProfile?.copyWith(avatarType: type) ??
        UserProfile(
          id: userId,
          displayName: 'User',
          avatarType: type,
          monthlyBudget: 0,
          currency: 'INR',
        );
    profileNotifier.value = updatedProfile;

    // Sync to Supabase
    try {
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'avatar_type': type.name,
      });
      debugPrint('ProfileService: Avatar updated in Supabase');
    } catch (e) {
      debugPrint('ProfileService: Error updating avatar: $e');
    }
  }

  /// Update monthly budget in Supabase
  Future<void> updateMonthlyBudget(double budget) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    // Update local state immediately
    final currentProfile = profileNotifier.value;
    final updatedProfile =
        currentProfile?.copyWith(monthlyBudget: budget) ??
        UserProfile(
          id: userId,
          displayName: 'User',
          avatarType: AvatarType.male,
          monthlyBudget: budget,
          currency: 'INR',
        );
    profileNotifier.value = updatedProfile;

    // Sync to Supabase
    try {
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'monthly_budget': budget,
      });
    } catch (e) {
      debugPrint('ProfileService: Error updating budget: $e');
    }
  }

  /// Update currency in Supabase
  Future<void> updateCurrency(String currency) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    // Update local state immediately
    final currentProfile = profileNotifier.value;
    final updatedProfile =
        currentProfile?.copyWith(currency: currency) ??
        UserProfile(
          id: userId,
          displayName: 'User',
          avatarType: AvatarType.male,
          monthlyBudget: 0,
          currency: currency,
        );
    profileNotifier.value = updatedProfile;

    // Sync to Supabase
    try {
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'currency': currency,
      });
    } catch (e) {
      debugPrint('ProfileService: Error updating currency: $e');
    }
  }

  /// Clear profile data (on logout)
  Future<void> clearProfile() async {
    debugPrint('ProfileService: Clearing profile');
    profileNotifier.value = null;
  }

  /// Get avatar emoji based on type
  static String getAvatarEmoji(AvatarType type) {
    switch (type) {
      case AvatarType.male:
        return '👨';
      case AvatarType.female:
        return '👩';
      case AvatarType.neutral:
        return '👤'; // Blank/neutral profile
    }
  }
}
