# JP AUCTION ARENA

Responsive cricket player auction management application for Web, Android,
iOS, and Windows. Auctions are the product's primary workflow; this is not a
general tournament management system. The app uses Material 3, Riverpod,
GoRouter, a shared JP AUCTION ARENA design system, and a responsive shell.

## Requirements

- Flutter SDK with Dart 3.9 or later
- Platform toolchains for the targets you want to run (Android Studio, Xcode,
  Visual Studio, or a supported browser)

## Run locally

```shell
flutter pub get
flutter run -d chrome
```

For another configured target, use `flutter devices` to find its device ID and
run `flutter run -d <device-id>`.

## Verify

```shell
flutter analyze
flutter test
flutter build web
```

## Project structure

- `lib/app.dart`: root Flutter application composition.
- `lib/core/`: configuration, routing, theme, responsive breakpoints, errors,
  and shared state conventions.
- `lib/shared/`: reusable components and responsive application shell.
- `lib/features/`: feature-owned presentation, application, domain, and data
  layers. Auction creation, pre-live configuration, status management, and
  history use in-memory repositories. Team/player registration and live bidding
  are not implemented or connected to auctions.

The legacy `/app/tournaments` URL redirects to Auctions; its source is retained
for compatibility and is not the product's primary workflow.

Feature work should keep domain contracts independent of Flutter and data
providers. Put feature-specific Riverpod providers/notifiers alongside their
feature, expose repository contracts from the domain layer, and implement them
in the data layer. Use `AsyncValue` with the shared async-state widgets for
loading, error, and data rendering.

## Demo authentication

The local demo authentication is for development and tests only. It is
in-memory, does not persist sessions across app restarts, and is not production
authentication. Demo credentials are synthetic and must never be reused as
real account credentials:

| Role | Email | Password |
|---|---|---|
| Super Admin | `admin@demo.jp` | `DemoAdmin!2026` |
| Tournament Admin / Auction Operator | `operator@demo.jp` | `DemoOperator!2026` |
| Team Owner / Team Manager | `team@demo.jp` | `DemoTeam!2026` |
| Public Viewer | `viewer@demo.jp` | `DemoViewer!2026` |

Auction records and demo authentication use in-memory local implementations;
data is volatile and demo records are not real auctions. Live bidding,
auction-specific team/player registrations, bid history, Supabase, PostgreSQL,
Node.js services, payments, and realtime integrations are not connected.
Replace `AuthRepository` with a Supabase Authentication adapter only in a
future approved phase.
See [docs/APP_BLUEPRINT.md](docs/APP_BLUEPRINT.md),
[docs/APP_NAVIGATION_FLOW.md](docs/APP_NAVIGATION_FLOW.md), and
[docs/FEATURE_ROADMAP.md](docs/FEATURE_ROADMAP.md) for the agreed product
direction and planned work.
