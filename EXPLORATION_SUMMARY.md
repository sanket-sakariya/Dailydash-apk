# DailyDash Codebase Exploration - Executive Summary

**Date:** April 23, 2026  
**Project:** Personal Expense Tracker (DailyDash)  
**Status:** Active Development with Supabase Integration

---

## Quick Reference

| Aspect | Details |
|--------|---------|
| **App Type** | Personal Finance Management |
| **Language** | Dart/Flutter (SDK ^3.11.3) |
| **Architecture** | Clean Architecture with Repository Pattern |
| **State Management** | ValueNotifier (No external library) |
| **Backend** | Supabase (PostgreSQL + Auth) |
| **Local DB** | SQLite (native) / In-Memory (web) |
| **UI Framework** | Material Design 3 |
| **Platforms** | Android, iOS, macOS, Linux, Windows, Web |
| **Total Code** | ~6,000 LOC (screens) + supporting code |
| **Files** | 19 Dart files |

---

## 5-Minute Overview

### What Is This App?

**DailyDash** is a cross-platform personal expense tracking application that helps users:
- 📊 Track daily expenses and income across 9 categories
- 💰 Set and monitor monthly budgets
- 📈 View analytics with pie/bar charts
- 📄 Export financial reports as PDF
- 💱 Support multiple currencies (8 total)
- 🔐 Sync data securely to the cloud via Supabase
- 🌓 Switch between dark and light themes

**Key Innovation:** Offline-first architecture with automatic cloud sync using the Outbox pattern. Data is written locally first, ensuring responsive UI, then synced to the cloud in the background.

---

## Directory Structure (High Level)

```
lib/
├── main.dart (Entry + Global State + Auth Gate)
├── config/ (Supabase credentials)
├── models/ (Expense data model with sync metadata)
├── database/ (Repository Pattern)
│   ├── data_repository.dart (Abstract interface)
│   ├── database_helper.dart (SQLite for native)
│   └── in_memory_repository.dart (Web/testing)
├── screens/ (Main UI components)
│   ├── dashboard_screen.dart (Main overview)
│   ├── add_expense_screen.dart (Custom numpad entry)
│   ├── analytics_screen.dart (Charts & insights)
│   ├── all_transactions_screen.dart (Full list)
│   ├── settings_screen.dart (Profile & export)
│   └── auth/ (Login, password, email screens)
├── services/ (Business logic)
│   ├── auth_service.dart (Supabase auth)
│   ├── sync_service.dart (Bi-directional sync)
│   └── profile_service.dart (User profile)
├── theme/ (Design system)
└── widgets/ (Reusable components)
```

---

## Features & Screens

### Main Screens (3 Tabs)

| Screen | Purpose | Size |
|--------|---------|------|
| **Dashboard** | Financial overview, recent transactions | 1,148 LOC |
| **Analytics** | Charts, trends, insights | 892 LOC |
| **Settings** | Profile, preferences, PDF export | 2,389 LOC |

### Secondary Screens

- **Add/Edit Expense:** Custom numpad, category picker, date/time selection (854 LOC)
- **All Transactions:** Full history with filtering, search, sort (785 LOC)
- **Authentication:** Login, change password, change email
- **Profile Management:** Avatar selection, display name, settings

---

## State Management

**Architecture:** ValueNotifier (Lightweight)

No external state management library (Riverpod, BLoC, Provider). Instead, uses Flutter's built-in `ValueNotifier` for a simpler, smaller codebase.

### Global State
```dart
// In main.dart - accessible from anywhere
final currencyNotifier = CurrencyNotifier();      // ↔ ProfileService
final languageNotifier = LanguageNotifier();
final usernameNotifier = UsernameNotifier();      // ↔ ProfileService
final budgetNotifier = BudgetNotifier();          // ↔ ProfileService
final darkModeNotifier = DarkModeNotifier();
final avatarNotifier = AvatarNotifier();          // ↔ ProfileService
final profileImageNotifier = ProfileImageNotifier();
final notificationsNotifier = NotificationsNotifier();
final navigationIndexNotifier = ValueNotifier<int>(); // Tab switching
```

### Service State
- **AuthService:** `authStateNotifier`, `currentUserNotifier`, error handling
- **SyncService:** `syncStatusNotifier`, `pendingCountNotifier`, connectivity state
- **ProfileService:** `profileNotifier`, `avatarImageNotifier`

---

## Database & Backend

### Dual Architecture

```
DataRepository (Abstract)
├── DatabaseHelper (SQLite - Native platforms)
└── InMemoryRepository (Array - Web/testing)
```

### Local Database (SQLite)
- **Name:** dailydash.db
- **Tables:** expenses, settings
- **Features:** Sync metadata (is_synced, is_deleted, last_modified)

### Cloud Backend (Supabase PostgreSQL)
- **Tables:** 
  - `public.expenses` - User expense records
  - `public.user_profiles` - User profile data
- **Security:** Row-Level Security (RLS) policies
- **Auth:** Email/password via Supabase Auth

### Synchronization (Outbox Pattern)
1. **Write Locally:** User action → SQLite (isSynced=0)
2. **Immediate UI:** Screen updates instantly
3. **Background Sync:** Push unsynced → Supabase
4. **Conflict Resolution:** Last-Write-Wins (last_modified timestamp)
5. **Pull Updates:** Fetch new/modified records
6. **Mark Synced:** Update isSynced=1

---

## Data Models

### Expense
```dart
class Expense {
  String id;           // UUID
  double amount;
  DateTime dateTime;
  String description;
  String category;     // 9 categories
  String paymentMode;  // 5 payment modes
  bool isIncome;
  
  // Sync metadata
  String userId;
  DateTime lastModified;
  bool isSynced;
  bool isDeleted;      // Soft delete
}
```

**Categories (9):** Food, Bills, Transport, Shop, Health, Housing, Entertainment, Education, Other

**Payment Modes (5):** UPI, Credit Card, Debit Card, Cash, Bank Transfer

### UserProfile
```dart
class UserProfile {
  String id;                    // UUID
  String displayName;
  AvatarType avatarType;        // male, female, neutral
  String? avatarImage;          // Base64
  double monthlyBudget;
  String currency;              // 8 currencies
}
```

---

## Services Layer

### AuthService (Singleton)
- Manages Supabase authentication
- Methods: signUp, signIn, signOut, changePassword, changeEmail, resetPassword
- State: currentUser, authState (unknown/authenticated/unauthenticated), error

### ProfileService (Singleton)
- Manages user profile data
- Methods: loadProfile, updateDisplayName, updateAvatarType, updateBudget, updateCurrency
- Features: Image compression, base64 encoding, auto-create on signup

### SyncService (Singleton)
- Bi-directional sync between SQLite and Supabase
- Monitors connectivity via `connectivity_plus`
- Methods: triggerSync, pushUnsynced, pullFromRemote, resolveConflicts
- Uses Last-Write-Wins for conflict resolution

---

## Testing

**Current State:** Minimal (Critical Gap ⚠️)

- Only 1 placeholder test exists
- No unit tests for business logic
- No widget tests for screens
- No integration tests for database operations
- No tests for sync functionality

**Challenges:**
- SharedPreferences initialization required
- Supabase mock/stub needed
- SQLite test database isolation
- ValueNotifier listener cleanup

---

## Dependencies (16 Total)

| Category | Packages |
|----------|----------|
| **Backend** | supabase_flutter (2.0.0) |
| **Local DB** | sqflite (2.4.2) |
| **Storage** | shared_preferences (2.5.3) |
| **UI/Charts** | fl_chart (0.70.2), google_fonts (6.2.1) |
| **Files** | image_picker, image, pdf, path_provider, open_file |
| **Network** | connectivity_plus (6.0.0) |
| **Utilities** | intl, uuid, path, cupertino_icons, device_preview |

---

## Architecture Patterns Used

| Pattern | Usage |
|---------|-------|
| **Repository** | Abstract interface for data operations, dual implementation |
| **Singleton** | DatabaseHelper, AuthService, SyncService, ProfileService |
| **Immutable Models** | `copyWith()` for safe updates, thread-safe |
| **Outbox** | Write local first, background sync to cloud |
| **Last-Write-Wins** | Compare `last_modified` timestamps for conflicts |
| **ValueNotifier** | Global state without external library |
| **Tab Navigation** | IndexedStack keeps screens in memory (O(1) switch) |
| **Platform Abstraction** | `kIsWeb` check for platform-specific code |

---

## Strengths ✅

1. **Clean Architecture** - Clear separation: UI → Services → Database
2. **Cross-Platform** - Single codebase runs on 6 platforms
3. **Offline-First** - Works without internet, syncs when available
4. **Security** - Supabase RLS enforces user data isolation
5. **Performance** - IndexedStack keeps state between tab switches
6. **Beautiful UI** - "Neon Nocturne" dark-first design system
7. **Complete Features** - Analytics, PDF export, budgeting, multi-currency
8. **Extensible** - Repository pattern makes testing & feature addition easy

---

## Areas for Improvement 🚀

| Issue | Priority | Impact |
|-------|----------|--------|
| **Test Coverage** | 🔴 Critical | No automated testing currently |
| **Error Handling** | 🟠 High | Basic error handling in services |
| **Logging** | 🟠 High | No centralized logging for debugging |
| **Pagination** | 🟡 Medium | Large transaction lists may be slow |
| **Caching** | 🟡 Medium | Analytics queries not cached |
| **Web Persistence** | 🟡 Medium | Web version uses in-memory (no data save) |
| **Real-time Sync** | 🟡 Medium | Uses polling, not real-time subscriptions |

---

## Known Limitations ⚠️

1. **Web:** No persistence (in-memory only, data lost on refresh)
2. **Sync:** Not real-time (polls only when connectivity changes)
3. **Images:** Base64 encoding may hit Supabase size limits
4. **Comments:** Limited inline documentation in complex screens
5. **Single User:** RLS policies enforce single-user access (by design)

---

## Quick Start for New Developers

### Prerequisites
- Flutter SDK ^3.11.3
- Supabase account
- Basic Dart/Flutter knowledge

### Setup Steps
1. Clone repository
2. Run `flutter pub get`
3. Update Supabase credentials in `lib/config/supabase_config.dart`
4. Create Supabase project and run `supabase/schema.sql`
5. Run `flutter run` on desired platform

### Adding a Feature
1. Add method to `DataRepository` interface
2. Implement in `DatabaseHelper` + `InMemoryRepository`
3. Create service class if needed (extends ValueNotifier pattern)
4. Build UI screen using `ValueListenableBuilder`
5. Write tests for repository methods

---

## Comprehensive Documentation Files Generated

✅ **CODEBASE_ANALYSIS.md** (30 KB)
- Complete architecture overview
- Detailed feature descriptions
- Code examples and patterns
- Database schemas with SQL
- Service documentation
- 14 major sections

✅ **ARCHITECTURE_DIAGRAM.txt**
- Visual ASCII diagrams
- Data flow illustrations
- Model serialization flows
- State management flows
- 7 detailed diagrams

✅ **EXPLORATION_SUMMARY.md** (This file)
- Executive summary
- Quick reference tables
- Key information at a glance

---

## Files to Review First

| File | Purpose | Why |
|------|---------|-----|
| lib/main.dart | App entry & state | Global state notifiers |
| lib/models/expense.dart | Data model | Understands sync metadata |
| lib/database/data_repository.dart | Interface | Understand all operations |
| lib/screens/dashboard_screen.dart | Main screen | Complex example screen |
| lib/services/sync_service.dart | Cloud sync | Core architecture feature |
| supabase/schema.sql | Database schema | Backend structure |

---

## Key Takeaways

1. **Sophisticated Architecture** - This is production-ready code with clean separation of concerns
2. **Offline-First Design** - Data syncs automatically without user intervention
3. **Scalable Pattern** - Repository pattern makes adding features straightforward
4. **Beautiful Code** - Immutable models, type-safe, well-organized
5. **Critical Gap** - Needs comprehensive test coverage
6. **Well-Documented** - 3 detailed analysis documents provided

---

**Generated:** April 23, 2026  
**Analysis by:** Claude Code  
**Status:** Complete ✅
