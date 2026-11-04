# Test Report

Validation is performed against the current local checkout. Platform results
are reported only for commands that were executed.

## Point 7 validation

- `flutter test` — passed, 86 tests.
- `flutter analyze` — passed with no issues.
- `flutter build web --release` — passed; output generated at `build/web`.
- `git diff --check` — passed.

Player tests cover auction isolation, same-auction uniqueness, search/category/
status filtering, role and operator-assignment restrictions, live-auction
mutation locks, availability changes, CSV import/export and atomic validation,
cross-auction team assignment rejection, protected auction results, and
registration form behavior.

The app remains a local demo implementation. These results do not verify
production backend security, cross-device synchronization, or other platform
builds.

## Point 8 validation

- `flutter analyze` — passed with no issues.
- `flutter test` — passed, 96 tests.
- `flutter build web --release` — passed; output generated at `build/web`.
- `git diff --check` — passed.

Auction rule tests cover fixed/tiered calculations, tier boundaries and
overlaps, base-price/purse/squad/category/timer validation, authorization,
auction isolation, Live-status write locks, and editing/saving through the
responsive settings screen. Player tests cover purse validation and configured
category base-price suggestions. These checks do not imply live bidding,
squad-limit enforcement, or durable persistence.
