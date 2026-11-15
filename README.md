# JP AUCTION ARENA

A professional cricket player auction management and live control room application built with Flutter, Material 3, Riverpod, and GoRouter. Designed for seamless execution on Web (PWA), Android (Release APK), iOS, and Desktop.

Featuring an ultra-modern dark navy, deep purple, electric blue, and neon pink visual identity with glassmorphism cards and responsive layouts.

---

## 🚀 Key Features

### 1. Auction Management & Rules
- Create, configure, edit, pause, and finalize multiple tournaments and auctions.
- Configurable purse limits, minimum/maximum squad sizes, base prices, and custom bid increment brackets.
- Strict single-live-auction enforcement preventing simultaneous live conflicts.

### 2. Live Auction Control Room
- Comprehensive operator dashboard with real-time auction timer, warning states, and hammer controls.
- Active player spotlight with portrait cards, role badges, strike rate, village, and base price.
- Dynamic player queue with reordering, nominating next, skipping, and returning players to pool.
- Live team purse tracker showing allocated purse, spent amount, remaining purse, and filled squad slots.
- Bidding war monitor and placeholder interface ready for real-time live bidding engines.
- Role-based permissions: Super Admin / Operator (full control), Team Owner / Manager (restricted), Public Viewer (read-only).

### 3. Team & Player Registration
- Comprehensive team creation with custom colors, logos, and allocated purse management.
- Player registry supporting photos, jersey numbers, cricketing categories (Batsman, Bowler, All-Rounder, Wicket Keeper), village origin, batting/bowling styles, and contact details.
- Guard against duplicate player jersey numbers within the same auction context.
- CSV import and export workflows with validation previews.

### 4. Advanced Analytics & Visualizations
- Interactive KPI cards: Total Auction Value, Average Player Price, Highest/Lowest Bids, Sold Ratio.
- Powered by `fl_chart`:
  - Team spending comparison horizontal bar chart.
  - Category spending distribution with player counts.
  - Bid timeline and activity curve.
  - Team purse balance donut charts.
  - Bidding War meter highlighting contested players.
  - Team squad balance rating matrix.
  - Price vs. Strike Rate scatter chart.
- Export analytics reports as images or print-ready views.

### 5. Settings, PWA & Data Portability
- Offline-first data persistence powered by Hive storage.
- Comprehensive backup and restore: Export state as encrypted JSON and restore across phone, tablet, and desktop.
- Double-confirmation security guards on destructive operations.
- App theming accents (Electric Blue, Royal Purple, Neon Pink) and font size scaling.
- Multilingual foundation (English, ગુજરાતી, हिन्दी).
- Progressive Web App (PWA) ready with service worker offline caching, manifest, and gradient iconography.
- Sound notifications and sold celebration animation controls.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: Flutter 3.x / Dart 3.9+
- **State Management**: Riverpod (`StateNotifierProvider`, `NotifierProvider`, `AsyncValue`)
- **Routing**: GoRouter with route guards and role-based redirects
- **Local Storage**: Hive with custom TypeAdapters (`HiveBoxes.init()`)
- **Visual Design**: Custom Dark Glassmorphism, Material 3, Google Fonts (Rajdhani & Inter)
- **Charts**: `fl_chart`
- **Feedback & States**: Custom shimmer skeletons (`AppSkeleton`), empty state illustrations (`AppEmptyState`), error states, and responsive confirmation dialogs (`AppConfirmationDialog`).

---

## 📱 Responsive Support

All views adapt across three distinct viewport tiers:
- **Mobile** (`< 600px`): Single-column stack, horizontal scroll wrappers, floating quick actions.
- **Tablet** (`600px - 1024px`): Balanced two-column grid, responsive side sheets.
- **Desktop** (`> 1024px`): Multi-column live control dashboard, permanent sidebar navigation, high-density telemetry.

---

## 💻 Local Setup & Development

### Prerequisites
- Flutter SDK (stable channel, >= 3.24)
- Dart SDK (>= 3.5 < 4.0)
- Chrome / Edge (for Web development) or Android Studio (for Android build)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Bhautik-Dev/jp_auction_arena.git
   cd jp_auction_arena
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Run code generation (if needed)**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Launch the application**:
    - Web:
      ```bash
      flutter run -d chrome
      ```
    - Android / Desktop:
      ```bash
      flutter run
      ```

### Supabase Configuration

JP AUCTION ARENA integrates with Supabase for cloud synchronization and real-time features.

**Your project is pre-configured** with the following defaults (safe client-side values only):

| Setting | Default Value |
|---|---|
| Project URL | `https://fxiiivbqrjxdnsvfegvy.supabase.co` |
| Publishable Key | `sb_publishable_dkaOxQ4DvKZnC0T8wIHk4A_1f4kPfnL` |

These defaults are embedded via `String.fromEnvironment(defaultValue: ...)` in
`lib/core/supabase/supabase_config.dart`. To override for a different project,
pass `--dart-define` at run time.

#### Security

- **Never** commit the Supabase **Secret / Service Role Key** (`sb_secret_*`) to source control.
- The secret key is **never** loaded by the client app — it is only used server-side.
- The publishable key is safe to ship in the app bundle (it is the anonymous key).

#### Run the App

No extra flags are required — the defaults will be used:

```bash
# Web
flutter run -d chrome

# Android / Desktop
flutter run
```

To override with a different Supabase project:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

#### Required Supabase Tables

The following tables must exist in your Supabase database:

| Table | Description |
|---|---|
| `profiles` | User profiles linked to Supabase Auth |
| `auctions` | Auction configurations |
| `auction_members` | Many-to-many relation between profiles and auctions |
| `teams` | Teams participating in an auction |
| `players` | Players registered in an auction |
| `bids` | Individual bid records |
| `auction_state` | Live auction operational state |
| `activity_log` | System event log for audit trails |

Dart models with `fromJson()` / `toJson()` are located in `lib/core/supabase/`.

#### Supabase Client Access

The Supabase client is exposed via Riverpod:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/core/supabase/supabase_provider.dart';

final client = ref.read(supabaseClientProvider);
```

#### Online/Offline Connection Status

The app monitors network connectivity using `connectivity_plus` and displays an
online/offline indicator in the AppBar (mobile) and sidebar (desktop). The
status is exposed via Riverpod:

```dart
import 'package:jp_auction_arena/core/connection/connection_service.dart';

final status = ref.watch(connectionStatusProvider);
```

Initialize the service in `main()`:

```dart
await ConnectionService.instance.init();
```

#### Repository Abstraction & Cloud Sync

The app uses a dual-storage architecture:
- **Hive** (local/offline): Single source of truth for the UI, always available.
- **Supabase** (cloud): Best-effort mirror of writes; never blocks the UI.

Repository abstraction interfaces are defined in `lib/data/repositories/`
and the active implementation is selected at startup by `RepositoryFactory`:

```dart
import 'package:jp_auction_arena/data/repositories/repository_factory.dart';

final bundle = ref.watch(repositoryFactoryProvider);
bundle.auction  // AuctionRepository (Hive or Supabase-backed)
bundle.player   // PlayerRepository
bundle.team     // TeamRepository
bundle.bid      // BidRepository
```

The `SupabaseSyncService` pushes local changes to Supabase best-effort —
failures are swallowed so the app remains fully functional offline.

---

## 🧪 Testing & Verification

Run the comprehensive unit, widget, and responsive test suites:

```bash
# Run all tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📦 Builds & Deployment

### 1. Progressive Web App (PWA) & GitHub Pages
The web app is automatically built and deployed to GitHub Pages via `.github/workflows/deploy.yml`.
To build manually:
```bash
flutter build web --release --base-href "/jp_auction_arena/"
```
The output is generated in `build/web` with service worker offline caching enabled.

### 2. Android Release APK
Build the release APK locally:
```bash
flutter build apk --release
```
The compiled APK will be at `build/app/outputs/flutter-apk/app-release.apk`.
GitHub Actions workflow `.github/workflows/build_apk.yml` automatically compiles and uploads the release APK artifact on pushes and version tags.

---

## 🔐 Demo Credentials

Synthetic demo logins for local sandbox exploration:

| Role | Email | Password | Access Level |
|---|---|---|---|
| **Super Admin** | `admin@demo.jp` | `DemoAdmin!2026` | Full system configuration, data wipe & restore |
| **Auction Operator** | `operator@demo.jp` | `DemoOperator!2026` | Live auction room operator, player nomination |
| **Team Manager** | `team@demo.jp` | `DemoTeam!2026` | Team roster management, purse view |
| **Public Viewer** | `viewer@demo.jp` | `DemoViewer!2026` | Read-only public leaderboard and stream |

---

## 📄 License & Attribution
Developed for **JP AUCTION ARENA** cricket tournament operations. All rights reserved.
