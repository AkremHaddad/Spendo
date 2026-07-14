# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Spendo** — a personal finance tracker (expense/income management) built with Flutter. Targets web, Android, and Windows. Backend is Firebase (Auth + Firestore). Firebase project ID: `spendo-56`, Firestore region: `europe-west8`.

## Commands

```bash
# Install dependencies
flutter pub get

# Run (choose target)
flutter run -d chrome       # web
flutter run -d windows      # desktop
flutter run                 # default connected device

# Build web for deployment
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy Firestore rules/indexes
firebase deploy --only firestore

# Static analysis
flutter analyze
```

## Architecture

### Feature-based structure

`lib/features/<feature>/` with four sub-layers:

- `presentation/` — the main page widget
- `logic/` — `ChangeNotifier` subclass (the notifier/view-model)
- `data/models/` — plain Dart model classes
- `widgets/` — reusable UI components for that feature

Features: `auth`, `cashflow`, `categories`, `dashboard`, `account`, `main`.

### State management

Uses **Provider** (`ChangeNotifier` + `ChangeNotifierProxyProvider`). All notifiers that need the logged-in user are wired with `ChangeNotifierProxyProvider<AuthNotifier, XNotifier>` in `main.dart` — they rebuild automatically when the user ID changes (login/logout).

Notifier locations:
- `lib/features/auth/auth_notifier.dart` — Firebase Auth state, login/signup/Google sign-in, creates default categories on first sign-up
- `lib/features/categories/logic/categoryNotifier.dart` — real-time Firestore listener on user categories
- `lib/features/cashflow/logic/cashflowNotifier.dart` — transactions for a selected date; writes update the `balances` doc atomically
- `lib/features/dashboard/logic/dashboardNotifier.dart` — aggregates Firestore data for charts
- `lib/features/main/theme_notifier.dart` — global `ThemeMode` toggle

### Firestore data model

All user data lives under `users/{userId}/`:
- `categories/{categoryId}` — category + nested products subcollection
- `cashflows/{cashflowId}` — individual transactions
- `balances/balance` — single document with `totalBalance`, `totalIncome`, `totalExpenses`

### Theming

`lib/core/theme/theme.dart` defines `AppColors` (static constants) and `AppTheme` (light/dark `ThemeData`). A `ThemeColorsExtension` on `ThemeData` exposes semantic color getters (`theme.base100`, `theme.accent`, `theme.success`, etc.) that automatically return the correct light/dark value. Always use these extension getters rather than raw `AppColors` constants in widgets.

```dart
final theme = Theme.of(context);
theme.base100       // background
theme.baseContent   // primary text
theme.accent        // red/danger
theme.secondary     // green/income
```

### Responsive layout

`lib/core/utils/responsive.dart` exports `isMobile(context)` — returns `true` when width < 600 px. Pages and the nav bar switch layout at this breakpoint. `mobile_navbar.dart` renders a `BottomNavigationBar`; `web_navbar.dart` renders a side rail.

## Known Issues & Planned Work (tracked 2026-07-14)

Full context lives in `C:\Projects\my profile\Second brain\04 Personal Projects\Spendo.md` and `C:\Projects\my profile\ROADMAP.md` (Phase 3) — this repo is part of Akram's career-development plan tracked there. Summary for working directly in this repo:

### Bugs, in priority order
1. **Money stored as floating point** — causes drift (e.g. totals like `126.36999998`) and wrong precision (UI shows 2 decimals; TND needs 3, i.e. millimes). Fix: refactor to store amounts as **integers in millimes** throughout (`cashflows`, `balances` doc, category budgets once they exist), only format to decimal string at the UI layer. Do this before other fixes below — several likely depend on/are masked by it.
2. **Net worth showed 0 once** — root cause unknown. Investigate after the integer-money refactor; may be a race condition in `balances/balance` writes (`cashflowNotifier`) or a bad read before data loads.
3. **Dashboard graphs don't refresh reactively** — only update after a manual tab refresh. `dashboardNotifier` likely does a one-shot fetch instead of a live Firestore listener like `categoryNotifier` uses — compare the two.
4. **Mobile-only bug**: selecting an old date in the calendar then adding a transaction should default the new transaction to that selected date — works on desktop/web, breaks on mobile. Check how the selected date is passed into the transaction form on the mobile layout (`mobile_navbar.dart` path) vs web.
5. **Firestore read/write pattern isn't optimized** — revisit once the data model settles post-refactor (not urgent, project isn't billed yet).

### Design
Category/product theming and overall UI polish are due a full pass — treat this as part of the wider "high-end UI/UX" push Akram is doing across his portfolio (see `PROFILE.md` → Positioning). Do the redesign after the data-layer bugs above are fixed, not before.

### Planned features, in priority order
1. Repeating transactions (rent, salary, etc. on a schedule)
2. Spending targets/budgets by category
3. Excel export of all transaction data
4. Rotating tips carousel — NOT a blog. A fixed pool of ~23 tips, one shown per week, cycling automatically (e.g. `week_of_year % 23`) so no manual updates needed
5. Simple rule-based "smart alerts" (e.g. category spend exceeds a rolling average or threshold) — keep intentionally simple/honest, not a real ML system

## Progress Tracking & GitHub Hygiene (standing rules, set 2026-07-14)

- **Write/maintain a real README.md** for this project (what it is, stack, screenshots once available) — this repo currently only has the framework default.
- **Keep `C:\Projects\my profile\Project Summaries\Spendo.md` (+ generated `.pdf`) up to date** as real implementation work happens — the polished, portfolio-ready summary. Foreground architecture/technique decisions (e.g. the money-as-integer-millimes fix, the reactive-listener fix for graphs) over a plain feature list — see `Project Summaries/_TEMPLATE.md` and `README.md` there for structure. This is separate from this CLAUDE.md (implementation detail) and the Second brain vault note (working notes/case-study draft).
- **Commit and push after each completed task/subtask**, not in one batch — Akram wants an active GitHub history. Standing authorization covers push to the existing remote; it does NOT cover creating a new remote repo (Akram does that himself) or force-pushing.
- Explain non-obvious architecture/technique decisions as they're made (not just implement silently) — Akram is using this work to learn architecture/patterns, not just to get working code.
