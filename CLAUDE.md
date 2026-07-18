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

`lib/core/theme/theme.dart` defines `SpendoColors` (static constants) and `AppTheme` (light/dark `ThemeData`). A `ThemeColorsExtension` on `ThemeData` exposes semantic color getters that automatically return the correct light/dark value — always use these rather than raw `SpendoColors` constants in widgets.

```dart
final theme = Theme.of(context);
theme.bg, theme.surface, theme.surface2   // page / card backgrounds
theme.ink, theme.ink2, theme.ink3         // text, muted text, faint text
theme.border
theme.accentColor, theme.accentInkColor   // brand mint, its foreground
theme.tintMintBg / tintMintInk            // + coral/butter/lavender/sky/rose,
                                           // each a soft bg + a vivid ink
theme.serif(size, {weight, color, letterSpacing})  // Instrument Serif —
theme.sans(size, {weight, color})                  // Instrument Sans
```

Note on `serif()`'s `letterSpacing` param: it's a **ratio multiplied by `size` internally** (default `-0.02`, i.e. -2% of font size), not an absolute pixel value — passing `-1` to get "1px tighter" actually produces `-1 * size` px of spacing and visibly collapses the text. Pass small ratios (`-0.02` to `-0.03`), or omit it for the default.

Legacy alias getters (`base300`, `baseContent`, `cardsColor`, `borderColor`, etc.) still exist forwarding to the tokens above, from before a rename — don't use them in new code, they're just there so old call sites keep compiling.

### Responsive layout

`lib/core/utils/responsive.dart` exports two distinct breakpoints — genuinely different questions, don't conflate them:
- `isMobile(context)` — width < 600px. Phone-sized type scale/padding; `mobile_navbar.dart` (bottom nav) vs `web_navbar.dart` (side rail) switch here.
- `isCompact(context)` — width < 900px (`Breakpoints.compact`). "Is there room for this side-by-side/multi-column layout" — paired cards, multi-column grids, and fixed-width side rails should stack/reduce columns below this, independently of the mobile check. Getting this wrong (checking `isMobile` where you meant `isCompact`) is a recurring overflow bug in this codebase — see Status 2026-07-18.

## Status (2026-07-18)

Another full session — AI coach depth, a compact-breakpoint overflow bug class fixed across three pages, real branding (replacing the framework-default logo/favicon), demo data + a Project Summary for portfolio use, and two full passes on the pre-signup landing page (the second replacing the first with a Claude Design import). 8 commits: `6b669e7`, `9b4ed48`, `9f72539`, `6a0c949`, plus this session's landing-page and follow-up commits.

- **AI coach expanded from 5 to 12 insight types** (`_buildCoachTips` in `dashboard_page.dart`): overall + per-category budget-goal overrun/near-limit alerts (using `Category.monthlyGoal`, previously unused by the coach), month-over-month category and income swings (thresholds scaled relative to the user's own prior spending, not fixed dollar amounts, so it holds at any income/currency scale), biggest single purchase, no-spend-day streaks, frequent-small-purchase detection, plus the existing pace/savings/weekday/logging-gap signals. This is what delivers the "simple rule-based smart alerts" planned feature below — don't build it again as a separate thing.
- **Fixed a real invisible-icon bug**: the coach badge's icon color reused the tint's `bg` token, which is intentionally ~12%-alpha translucent in dark theme (correct for card fills, not icon strokes) — swapped to `theme.bg` (opaque) which contrasts reliably in both themes. Tips tied to a specific category now show that category's real icon/color instead of a generic badge.
- **Compact-breakpoint overflow fixed** on Cashflow (summary strip → 2×2 grid, category rail stacks below the list instead of squeezing beside it), Achievements (3-column grid → 2 col below `compact`, **1 col below `isMobile`** — even 2 columns was too narrow for the name/description text on a real phone), and Budgets (filter pills scroll horizontally instead of relying on a `Spacer`). All three were the same root cause: branching on `isMobile` where `isCompact` was needed.
- **Real branding**: `_SpendoLogo` in `web_navbar.dart` and the browser favicon/PWA icons were still the framework-default "$" gradient box / generic multicolor placeholder. Replaced with a hand-authored SVG mark (`assets/images/logoMark.svg`) rasterized via headless Chrome + `sharp` for the favicon/manifest icon sizes. New filenames throughout (not overwriting the old placeholders in place) since favicons are cached very persistently by browsers.
- **Pre-signup landing page fully redesigned**, twice. First pass was a custom-built hero+form page (fixed a `letterSpacing` misunderstanding along the way — see Theming above). Second pass replaced it entirely with a port of a Claude Design project (`claude.ai/design`, synced via the `DesignSync` tool): nav with inline feature highlights instead of a separate feature-strip section, hero headline/stats, and the login/signup form embedded directly in the hero as a card with a segmented Sign up/Log in toggle — no more scrolling to a separate form section. Desktop is a single mostly-non-scrolling screen (`ConstrainedBox(minHeight: ...)` + `Center`, not `IntrinsicHeight` — see the gotcha note below). Final revision dropped the product-screenshot mockups entirely for a more minimalistic, text-first hero (mobile's phone-mockup image was also removed on request) — `heroDesktop.png`/`heroMobile.png` and their framing widgets (`_BrowserFrame`, `_PhoneFrame`, `_MockupFrame`) no longer exist in the final version.
- **Theme already defaults to system, confirmed working as-is**: `ThemeNotifier` defaults to `ThemeMode.system` and only persists an override once the user explicitly picks Light/Dark/System in Account settings — Akram asked for this behavior and it turned out to already be correctly implemented, no change needed.
- **Demo account + seed data for screenshots**: seeded ~3 months of realistic transactions/categories/budget-goals into a separate demo Firebase Auth account (not Akram's real data) via the Firebase Admin SDK (a service-account key, used locally and not committed) — for taking the marketing/portfolio screenshots used in the landing-page work and the new Project Summary below. Not part of the app's own code, just a one-off data-seeding script.
- **First completed Project Summary**: `C:\Projects\my profile\Project Summaries\Spendo.md` + `.pdf` — the money-as-integer-millimes fix, the unwritten-field balance-corruption bug, the two-tier responsive breakpoint pattern, and this session's other techniques are written up there in CV-ready detail. Keep it current per the Progress Tracking section below.

## Status (2026-07-17)

Big dashboard/Home-tab pass, done in one long session (interactive + an unsupervised overnight `/loop` continuation) — 6 commits: `21390a0`, `c364dfd`, `08acd48`, `094d6d6`, `225e456`, `39e59d7`.

- **New dashboard charts**: category spend donut (`widgets/category_donut_chart.dart`), weekday spending rhythm bar chart (`widgets/weekday_rhythm_chart.dart`), end-of-month forecast area chart (`widgets/forecast_area_chart.dart`) — all match the existing theme system (`theme.serif`/`theme.sans`, tint colors).
- **Home tab rebalanced**: AI coach moved under the streak/income-expense info (no longer its own full-width row); "Spending this month" (top 4 categories **by actual spend**, was previously just the first 4 in list order) moved under the "This month" summary card; recent activity trimmed from 7 to 5 items — two 1-left/2-right-stacked columns instead of mismatched full-width rows.
- **AI coach is now data-driven** (`_buildCoachTips` in `dashboard_page.dart`) — biggest expense category, pace-vs-income forecast, savings rate, weekday spending pattern, logging-gap nudge, computed from real Firestore data each build. Replaces the old hardcoded 3-tip static rotation. This *replaces* the "rotating tips carousel" planned feature below — that idea (a fixed pool of ~23 tips) is superseded, don't build both.
- **`core/utils/responsive.dart`** gained a second breakpoint: `Breakpoints.compact` (900px) / `isCompact(context)`, distinct from the existing `isMobile` (600px). Paired side-by-side cards (hero row, recent+summary, forecast+income-vs-spend, donut+weekday) now stack below 900px instead of 600px — the mobile/desktop *type-sizing* breakpoint and the *"is there room for two cards side by side"* breakpoint are genuinely different questions, don't conflate them again.
- **Global dialog/button theming** added to `core/theme/theme.dart` (`DialogThemeData`, `ElevatedButtonThemeData`, `TextButtonThemeData`, both light/dark) — every `AlertDialog` in the app (add/edit category, add/edit transaction, edit balance, etc.) now picks up the rounded/serif/mint-accent look automatically instead of Material defaults, without per-dialog styling. The category-type `DropdownButton` in the add-category dialog was replaced with a segmented pill toggle matching the rest of the app.
- **Non-obvious technique note, worth knowing before touching layout code here**: `IntrinsicHeight` + `LayoutBuilder` inside it **crashes** — Flutter cannot compute intrinsic dimensions through a `LayoutBuilder` ("does not support returning intrinsic dimensions"). Hit this twice tonight (`CategoryDonutChart`, then `_BudgetRingsCard`) — both were refactored to take an explicit `stacked`/layout hint from the caller instead of self-measuring via `LayoutBuilder`. Separately, `IntrinsicHeight`'s dry-layout pass can diverge from real layout by a few px for wrapped-text content in ways that persisted even after making every piece of text content deterministically-sized (fixed heights, `maxLines`) — root cause not fully pinned down (suspected web-font-metrics timing), so the hero row deliberately does **not** use `IntrinsicHeight`+`stretch` (unlike the other 3 paired rows, which do and are fine) — see the comment at its `Row(...)` in `dashboard_page.dart` before re-adding it there.
- Several `overflow: TextOverflow.ellipsis` **without `maxLines`** were fixed across dashboard/cashflow/categories/account pages — that combination is a no-op in Flutter (text just wraps instead of truncating single-line), not a rare mistake, worth grepping for if you see wrapped text that "should" be ellipsizing.

## Known Issues & Planned Work (tracked 2026-07-14, bugs section updated 2026-07-18)

Full context lives in `C:\Projects\my profile\Second brain\04 Personal Projects\Spendo.md` and `C:\Projects\my profile\ROADMAP.md` (Phase 3) — this repo is part of Akram's career-development plan tracked there. Summary for working directly in this repo:

### Bugs, in priority order

1. ✅ **Fixed 2026-07-14, commit `0cdd7ce`** — Money stored as floating point (caused drift like `126.36999998`, and only 2 decimals shown vs. TND's 3/millime precision). `Cashflow` and `Balance` now store `amountMillimes` (int) as the source of truth, in `lib/features/cashflow/data/models/cashflow.dart` and `lib/features/dashboard/data/models/balance.dart`. A `double get amount` compat getter means no widget code needed to change — they still read `.amount` as before. New Firestore docs write `amountMillimes`; reads fall back to the legacy `amount` (double) field for any doc written before this change, so no manual data migration was needed. Formatting helpers are in `lib/core/utils/money.dart` (`formatMillimes` does the 3-decimal TND display — **still not wired into any widget as of 2026-07-17**, that's the next step of the redesign pass below).
2. ✅ **Fixed 2026-07-14, commit `0cdd7ce`** — investigated the net-worth-0 report: found a real correctness bug in `CashflowNotifier.deleteCashflow` — it checked a stored `isIncome` field that `Cashflow.toJson()` never actually wrote, so the check was always `false`, meaning **deleting an income transaction was reversed as if it were an expense**, silently corrupting the balance (adding money back instead of removing it). Fixed to derive income/expense from the amount's sign, the same convention used everywhere else. Can't be 100% certain this was *the* exact incident Akram saw, but it's a real bug of exactly that shape and is now fixed.
3. ✅ **Fixed 2026-07-14, commit `0cdd7ce`** — dashboard graphs not refreshing reactively. `DashboardNotifier` was doing a one-shot `.get()` for the cashflows list (balance already had a live listener) — switched to `.snapshots().listen()`, matching the pattern `categoryNotifier` uses.
4. ✅ **Fixed 2026-07-14, committed by 2026-07-18** (commit `235f61d` or nearby) — mobile-only date-selection bug in `lib/features/main/main_page.dart`'s FAB handler. The uncommitted-WIP caution that used to be here no longer applies as of 2026-07-18 — `web_navbar.dart`, `main_page.dart`, etc. were all clean (no pending WIP) at the start of that session, and `web_navbar.dart` was freely edited for the branding work above with no conflict.
5. **Firestore read/write pattern isn't optimized** — still open, revisit once the data model/redesign settle (not urgent, project isn't billed yet).
6. `category_pie_chart.dart`, `daily_line_chart.dart`, `weekly_bar_chart.dart`, `balance_line_chart.dart` in `lib/features/dashboard/widgets/` are **dead code** — confirmed unused anywhere in the app (pre-redesign leftovers). Safe to delete; flagged but not removed as of 2026-07-17 since they weren't in scope for that session's work.

### Design
Category/product theming and overall UI polish are due a full pass — treat this as part of the wider "high-end UI/UX" push Akram is doing across his portfolio (see `PROFILE.md` → Positioning). The dashboard's Home tab, the app's dialogs (2026-07-17), and the pre-signup landing page + real branding/logo/favicon (2026-07-18, see Status above) all got a real pass; **categories page icons and the category/transaction form fields themselves are still the old default-Material look** (`CategoryDropdown`, `ProductDropdown`, `AmountInput`, `DatePickerField` in `lib/features/cashflow/widgets/` — generic `DropdownButtonFormField`/`TextField`, no custom styling beyond what the new global `InputDecorationTheme`/`DialogTheme` give them for free) — that's the next concrete step of this redesign pass. Also still open: wire `formatMillimes()` from `core/utils/money.dart` into the ~15 widgets currently displaying `.amount` (a `double`) directly via `toStringAsFixed(2)` or similar — they need to switch to reading `.amountMillimes` and formatting with `formatMillimes()` to actually show TND's 3 decimals; the data layer supports it but no UI currently uses it yet.

**Deployment note**: the last `firebase deploy` predates the 2026-07-18 landing-page redesign (Akram asked to push the code but hold off deploying) — check `git log` vs. what's actually live at spendo-56.web.app before assuming they match.

### Planned features, in priority order
1. Repeating transactions (rent, salary, etc. on a schedule)
2. Spending targets/budgets by category — **partially covered 2026-07-18**: the AI coach now surfaces budget-goal overrun/near-limit alerts using `Category.monthlyGoal`. The Budgets page itself (setting/viewing goals per category) already existed; what's still open is any UI polish there, not the underlying feature.
3. Excel export of all transaction data
4. ~~Rotating tips carousel~~ — superseded 2026-07-17 by the data-driven AI coach; don't build this too, it'd be redundant.
5. ~~Simple rule-based "smart alerts"~~ — delivered 2026-07-18 as part of the expanded AI coach (budget-goal alerts, month-over-month category/income swing detection) — see Status above. Don't build a separate "smart alerts" feature, it'd duplicate this.

## Progress Tracking & GitHub Hygiene (standing rules, set 2026-07-14)

- **Write/maintain a real README.md** for this project (what it is, stack, screenshots once available) — this repo currently only has the framework default.
- **Keep `C:\Projects\my profile\Project Summaries\Spendo.md` (+ generated `.pdf`) up to date** as real implementation work happens — the polished, portfolio-ready summary. Foreground architecture/technique decisions (e.g. the money-as-integer-millimes fix, the reactive-listener fix for graphs) over a plain feature list — see `Project Summaries/_TEMPLATE.md` and `README.md` there for structure. This is separate from this CLAUDE.md (implementation detail) and the Second brain vault note (working notes/case-study draft).
- **Commit and push after each completed task/subtask**, not in one batch — Akram wants an active GitHub history. Standing authorization covers push to the existing remote; it does NOT cover creating a new remote repo (Akram does that himself) or force-pushing.
- Explain non-obvious architecture/technique decisions as they're made (not just implement silently) — Akram is using this work to learn architecture/patterns, not just to get working code.
