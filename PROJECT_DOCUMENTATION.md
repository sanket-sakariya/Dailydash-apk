# Personal Expense Tracker - Complete Documentation

> A comprehensive Flutter expense tracking application with analytics, multi-currency support, and PDF export capabilities.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Design](#architecture--design)
3. [Folder Structure](#folder-structure)
4. [Data Models](#data-models)
5. [Database Layer & CRUD Operations](#database-layer--crud-operations)
6. [Screens & Features](#screens--features)
7. [Theme System](#theme-system)
8. [State Management](#state-management)
9. [Dependencies](#dependencies)
10. [Platform Support](#platform-support)

---

## Project Overview

**App Name:** Personal Expense Tracker (DailyDash)  
**Framework:** Flutter (Dart)  
**Database:** SQLite (native) / In-Memory (web)  
**Design System:** "Neon Nocturne" - Dark-first with Material3 compliance

### Core Capabilities
- Track expenses and income
- Categorize transactions (9 categories)
- Multiple payment modes (5 options)
- Monthly budgeting with savings tracking
- Visual analytics (pie & bar charts)
- PDF report generation
- Multi-currency support (8 currencies)
- Dark/Light theme modes

---

## Architecture & Design

### Design Pattern
- **Repository Pattern** with abstract interface for database operations
- **Singleton Pattern** for database helpers
- **ValueNotifier** for lightweight state management (no complex state management library)
- **Immutable Model Pattern** with `copyWith()` for data models

### Navigation
- Tab-based bottom navigation
- 3 main screens: Dashboard, Analytics, Settings
- Uses `IndexedStack` for performance (preserves state across tabs)
- `GlobalKey` usage for screen refresh on tab switch

### Data Flow
```
UI (Screens) 
    ↓
ValueNotifiers (Global State)
    ↓
DataRepository (Abstract Interface)
    ↓
DatabaseHelper (SQLite) OR InMemoryRepository (Web)
```

---

## Folder Structure

```
lib/
├── main.dart              # Entry point, global state, app initialization
├── database/
│   ├── data_repository.dart       # Abstract interface (17 operations)
│   ├── database_helper.dart       # SQLite implementation
│   └── in_memory_repository.dart  # Web/testing implementation
├── models/
│   └── expense.dart       # Expense data model
├── screens/
│   ├── dashboard_screen.dart      # Main dashboard & transactions
│   ├── add_expense_screen.dart    # Add/Edit expense form
│   ├── analytics_screen.dart      # Charts & insights
│   └── settings_screen.dart       # Preferences & export
└── theme/
    └── app_theme.dart     # Theme definitions & colors
```

---

## Data Models

### Expense Model (`lib/models/expense.dart`)

```dart
class Expense {
  final int? id;           // Auto-increment primary key (nullable for new entries)
  final double amount;     // Transaction amount
  final DateTime dateTime; // When the transaction occurred
  final String description;// User-provided description
  final String category;   // One of 9 predefined categories
  final String paymentMode;// Payment method used
  final bool isIncome;     // true = income, false = expense
}
```

#### Categories (9 total)
| Category      | Icon                |
|---------------|---------------------|
| Food          | Icons.restaurant    |
| Bills         | Icons.receipt_long  |
| Transport     | Icons.directions_car|
| Shop          | Icons.shopping_bag  |
| Health        | Icons.medical_services |
| Housing       | Icons.home          |
| Entertainment | Icons.movie         |
| Education     | Icons.school        |
| Other         | Icons.category      |

#### Payment Modes (5 total)
- UPI
- Credit Card
- Debit Card
- Cash
- Bank Transfer

#### Serialization Methods
```dart
Map<String, dynamic> toMap()      // Convert to database format
factory Expense.fromMap(Map)      // Deserialize from database
Expense copyWith({...})           // Immutable update pattern
```

---

## Database Layer & CRUD Operations

### Abstract Repository Interface (`lib/database/data_repository.dart`)

Defines 17 core database operations:

```dart
abstract class DataRepository {
  // === CRUD Operations ===
  Future<int> insertExpense(Expense expense);
  Future<int> updateExpense(Expense expense);
  Future<int> deleteExpense(int id);
  Future<List<Expense>> getAllExpenses();
  
  // === Date-Based Queries ===
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);
  Future<List<Expense>> getExpensesForMonth(int year, int month);
  
  // === Analytics & Aggregations ===
  Future<double> getTotalSpentThisMonth();
  Future<double> getTotalSpentLastMonth();
  Future<Map<String, double>> getCategorySpending();
  
  // === Trend Analysis ===
  Future<List<Map<String, dynamic>>> getWeeklySpending();
  Future<List<Map<String, dynamic>>> getDailySpending();
  Future<List<Map<String, dynamic>>> getMonthlySpending();
  
  // === Insights ===
  Future<double> getAverageDailySpend();
  Future<String> getHighestCategory();
  Future<double> getSavings(double budget);
  Future<double> getBudgetPercentage(double budget);
}
```

### SQLite Implementation (`lib/database/database_helper.dart`)

**Database:** `dailydash.db`

#### Tables Schema

```sql
-- expenses table
CREATE TABLE expenses(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL NOT NULL,
  dateTime TEXT NOT NULL,      -- ISO 8601 format
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  paymentMode TEXT NOT NULL,
  isIncome INTEGER NOT NULL    -- 0 = expense, 1 = income
)

-- settings table (key-value storage)
CREATE TABLE settings(
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
```

#### CRUD Operations Implementation

**CREATE - Insert Expense:**
```dart
Future<int> insertExpense(Expense expense) async {
  final db = await database;
  return await db.insert('expenses', expense.toMap());
}
```

**READ - Get All Expenses:**
```dart
Future<List<Expense>> getAllExpenses() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'expenses',
    orderBy: 'dateTime DESC'
  );
  return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
}
```

**UPDATE - Update Expense:**
```dart
Future<int> updateExpense(Expense expense) async {
  final db = await database;
  return await db.update(
    'expenses',
    expense.toMap(),
    where: 'id = ?',
    whereArgs: [expense.id],
  );
}
```

**DELETE - Remove Expense:**
```dart
Future<int> deleteExpense(int id) async {
  final db = await database;
  return await db.delete(
    'expenses',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

#### Analytics Queries

**Category Spending (Grouped):**
```sql
SELECT category, SUM(amount) as total 
FROM expenses 
WHERE isIncome = 0 
GROUP BY category
```

**Monthly Spending:**
```sql
SELECT strftime('%Y-%m', dateTime) as month, SUM(amount) as total 
FROM expenses 
WHERE isIncome = 0 
GROUP BY month 
ORDER BY month DESC 
LIMIT 12
```

**Daily Spending (Last 7 days):**
```sql
SELECT strftime('%Y-%m-%d', dateTime) as day, SUM(amount) as total 
FROM expenses 
WHERE dateTime >= ? AND isIncome = 0 
GROUP BY day 
ORDER BY day
```

### In-Memory Implementation (`lib/database/in_memory_repository.dart`)

Used for:
- Web platform (SQLite WASM unreliable)
- Testing purposes
- Demo/sample data

Features:
- Array-based storage in memory
- Pre-seeded with sample transactions
- Implements same interface as DatabaseHelper
- Data does not persist across sessions

---

## Screens & Features

### 1. Dashboard Screen (`lib/screens/dashboard_screen.dart`)

**Main financial overview and transaction management**

#### UI Components:
| Component | Description |
|-----------|-------------|
| Total Spent Card | Gradient header showing monthly expense with % change vs last month |
| Savings Card | Budget vs actual (cyan = under budget, red = over budget) |
| Budget Card | Set/edit monthly budget with % used progress indicator |
| Recent Transactions | Last 10 expenses grouped by date (TODAY/YESTERDAY/Date) |
| Transaction Modal | Full details view with edit/delete options |
| FAB | Floating button to add new expense |

#### Features:
- Real-time data refresh on screen focus
- Budget percentage warning (red at 80%+)
- Transaction editing and deletion
- Date grouping for transactions

---

### 2. Add Expense Screen (`lib/screens/add_expense_screen.dart`)

**Transaction entry form with custom numpad**

#### UI Components:
| Component | Description |
|-----------|-------------|
| Amount Display | Large typography with cursor animation |
| Custom Numpad | 4x3 grid (0-9, decimal, backspace) with haptic feedback |
| Category Picker | 9 icon-based category selection |
| Payment Mode | 5 payment method options |
| DateTime Picker | Full date and time selection with custom theming |
| Description Field | Optional text input (defaults to category name) |
| Income Toggle | Switch between expense/income |
| Confirm Button | Gradient save button with animation |

#### Smart Input Features:
- Maximum 2 decimal places
- Auto-clear leading zero
- Full-screen layout (no keyboard resize issues)
- Confirmation animation on save

---

### 3. Analytics Screen (`lib/screens/analytics_screen.dart`)

**Visual insights and spending analysis**

#### Visualizations:

**1. Donut Chart (Category Distribution)**
- Color-coded segments by category
- Total spent display in center
- Legend with percentages and amounts

**2. Bar Chart (Trend Analysis)**
- Switchable views: Daily / Weekly / Monthly
- Gradient bars (cyan, brighter for recent)
- Auto-scaled based on max value

**3. Statistics Cards:**
| Card | Data Shown |
|------|------------|
| Highest Category | Top spending category with icon |
| Average Daily | Average daily spend amount |
| Monthly Breakdown | Month-over-month comparison |

**4. Smart Insight Card**
- AI-style suggestions comparing current vs previous periods
- Spending trend analysis

---

### 4. Settings Screen (`lib/screens/settings_screen.dart`)

**User preferences and data export**

#### Settings Options:

**Profile Management:**
- Username editing
- Profile image picker (Camera/Gallery/Remove)
- Custom avatar display

**Preferences:**
| Setting | Options |
|---------|---------|
| Currency | USD, EUR, GBP, JPY, INR, CAD, AUD, CHF |
| Language | 7 language options |
| Dark Mode | Toggle switch |
| Notifications | Enable/Disable |

**Report Export (PDF):**
- Period Options:
  - Current Month
  - Last Month
  - Last Year
  - Custom Date Range
  - All Time

- PDF Contents:
  - Header with username and generation date
  - Period information
  - Total transactions count
  - Category breakdown table with % distribution
  - Detailed transaction table (date, description, category, payment mode, amount)
  - Supports all 8 currencies with proper symbols
  - Uses NotoSans font for Unicode support

---

## Theme System

### Design System: "Neon Nocturne"

Located in `lib/theme/app_theme.dart`

#### Color Palette

| Color Role | Dark Mode | Light Mode |
|------------|-----------|------------|
| Primary | #DB90FF (Electric Purple) | #B060E0 |
| Secondary | #04C4FE (Cyan) | #0099CC |
| Background | #0E0E0E (True Black) | #F5F5F7 |
| Surface | #0E0E0E | #FFFFFF |

#### Surface Hierarchy
7 levels of surface containers for depth perception in dark mode

#### Chart Colors
| Index | Color | Usage |
|-------|-------|-------|
| 0 | Purple | Primary data |
| 1 | Cyan | Secondary data |
| 2 | Pink | Tertiary data |
| 3 | Orange | Quaternary data |

#### Typography
- Font Family: Plus Jakarta Sans (Google Fonts)
- Body: Regular weight for content
- Headlines: Bold for emphasis

#### Custom Extension
```dart
extension DailyDashColorsExtension on BuildContext {
  // Access custom colors via context
  Color get primaryColor => ...
  Color get surfaceColor => ...
}
```

---

## State Management

### Global ValueNotifiers (in `lib/main.dart`)

```dart
// Currency selection (default: USD)
final ValueNotifier<String> currencyNotifier = ValueNotifier('USD');

// Monthly budget amount
final ValueNotifier<double> budgetNotifier = ValueNotifier(0.0);

// Theme mode toggle
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(true);

// User display name
final ValueNotifier<String> usernameNotifier = ValueNotifier('User');

// Profile image file path
final ValueNotifier<String?> profileImageNotifier = ValueNotifier(null);

// Language preference
final ValueNotifier<String> languageNotifier = ValueNotifier('English');

// Notification toggle
final ValueNotifier<bool> notificationsNotifier = ValueNotifier(true);
```

### Currency Symbols Map
```dart
const currencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'INR': '₹',
  'CAD': 'C\$',
  'AUD': 'A\$',
  'CHF': 'CHF',
};
```

### Persistence
- Settings stored in SQLite `settings` table
- Profile image stored as file in app directory
- Retrieved on app startup

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| sqflite | 2.4.2 | SQLite database (native platforms) |
| shared_preferences | 2.5.3 | Settings persistence |
| fl_chart | 0.70.2 | Pie and bar chart visualizations |
| intl | 0.20.2 | Date/number formatting |
| image_picker | 1.1.2 | Camera and gallery image selection |
| pdf | 3.11.0 | PDF generation |
| path_provider | 2.1.2 | App directory access |
| open_file | 3.5.6 | Open generated PDFs |
| device_preview | 1.2.0 | Multi-device testing |
| google_fonts | 6.2.1 | Plus Jakarta Sans typography |
| cupertino_icons | 1.0.8 | iOS-style icons |

---

## Platform Support

| Platform | Database | Status |
|----------|----------|--------|
| Android | SQLite | ✅ Full Support |
| iOS | SQLite | ✅ Full Support |
| macOS | SQLite | ✅ Full Support |
| Linux | SQLite | ✅ Full Support |
| Windows | SQLite | ✅ Full Support |
| Web | In-Memory | ⚠️ Limited (no persistence) |

### Platform-Specific Logic
```dart
// In main.dart
DataRepository repository;
if (kIsWeb) {
  repository = InMemoryRepository();
} else {
  repository = DatabaseHelper();
}
```

---

## Key Architectural Decisions

1. **Simple State Management**: ValueNotifiers instead of complex solutions (Riverpod, Bloc)
2. **Dual Repository Pattern**: Single codebase works on web and native platforms
3. **Platform-Specific Database**: SQLite for native, in-memory for web
4. **Singleton Database Access**: Ensures single connection throughout app lifecycle
5. **Immutable Data Models**: Using `copyWith()` for safe updates
6. **Theme Extension Pattern**: Custom colors accessible via BuildContext
7. **Gradient-Heavy UI**: Consistent visual depth using gradients throughout

---

## Summary

This expense tracker provides a complete financial management solution with:
- **Full CRUD** for expenses/income
- **Real-time analytics** with multiple chart types
- **Budgeting system** with savings tracking
- **Multi-currency** and multi-language support
- **PDF export** for reports
- **Cross-platform** deployment (6 platforms)
- **Cohesive dark-first design** with Material3 compliance

The architecture prioritizes simplicity (ValueNotifiers over complex state management) while maintaining clean separation of concerns through the repository pattern.
