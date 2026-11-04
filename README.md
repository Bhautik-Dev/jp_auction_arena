# JP AUCTION ARENA

Responsive Flutter application foundation for Web, Android, iOS, and Windows.
The app uses Material 3, Riverpod, GoRouter, a shared JP AUCTION ARENA design
system, and a responsive navigation shell.

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
  layers. Only the foundation dashboard and settings placeholder are currently
  implemented; planned module destinations are marked as coming soon.

Feature work should keep domain contracts independent of Flutter and data
providers. Put feature-specific Riverpod providers/notifiers alongside their
feature, expose repository contracts from the domain layer, and implement them
in the data layer. Use `AsyncValue` with the shared async-state widgets for
loading, error, and data rendering.

The application currently uses local UI state only. There is no authentication,
backend, database, auction engine, payment, or realtime service integration.
See [docs/APP_BLUEPRINT.md](docs/APP_BLUEPRINT.md),
[docs/APP_NAVIGATION_FLOW.md](docs/APP_NAVIGATION_FLOW.md), and
[docs/FEATURE_ROADMAP.md](docs/FEATURE_ROADMAP.md) for the agreed product
direction and planned work.
