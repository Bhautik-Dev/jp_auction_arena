# JP AUCTION ARENA

Flutter application foundation for a responsive cricket auction management
experience on web, Android, iOS, and Windows.

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
```

The application currently provides its shared Material 3 design system,
responsive navigation shell, dashboard placeholder, and the existing in-memory
tournament screens. No backend or database is connected.
