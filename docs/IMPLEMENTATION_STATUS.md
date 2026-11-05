# Implementation Status

This status describes the current checked-out implementation. It does not
claim production readiness or completion of the full product scope.

## Completed foundations

- **Points 1-2:** auction-first product blueprint, Flutter/Riverpod/GoRouter
  foundation, Material 3 design system, responsive shell, and shared widgets.
- **Points 3-4:** local demo authentication, role/route access foundation, and
  role-aware dashboard.
- **Point 5:** auction creation, edit, details, settings, lifecycle, history,
  in-memory repository, and single-Live-auction validation.
- **Point 6:** auction-scoped team registration, editing, search/status
  filtering, details, archive/restore, CSV text import/export, role and
  operator-assignment checks, auction capacity and duplicate checks.
- **Point 7:** auction-scoped player registration, profile/statistics,
  search/category/status filters, pre-live edits, availability, CSV text
  import/export, route/service access checks, auction isolation, and safe
  retention of sold/unsold registrations.
- **Point 8:** per-auction fixed or tiered bid increments, tier-range
  validation/next-bid calculation, player base-price defaults, category and
  optional overseas/wicketkeeper limits, timer/extension settings, player
  ordering, and unsold re-entry configuration. The responsive editor includes
  rule summaries and Save/Cancel. Auction details display a rule summary;
  player registration suggests the configured category/default base price.
  Domain services validate purse, squad, base prices, configured limits, timer
  and increment rules; rule access is role/auction scoped and writes are locked
  after Live.
- **Point 9:** auction-scoped team purse and squad summaries; spent and
  remaining purse calculation from recorded sold-player prices; timestamped,
  reasoned, append-only initial-purse adjustments with an atomic balance floor;
  category, overseas, wicketkeeper, squad-size, and future-purchase validation;
  assigned-team-only manager views and admin/operator team details; responsive
  purse/squad panels; and overseas-player classification in player forms and
  optional CSV import/export.
- **Point 10:** auction-scoped player preparation and queue; eligibility
  review, category/status/base-price/eligibility filters, queue add/remove,
  manual drag and move controls, explicit random and category ordering, and a
  readiness checklist. Domain services enforce auction isolation, operator
  assignment, role permissions, queue integrity, and readiness before Draft →
  Ready or Ready → Live transitions. Critical queue changes are locked after
  the auction starts.

Point 9 verification: `flutter analyze` passed; `flutter test` passed (108
tests); `flutter build web --release` passed; `git diff --check` passed.

Point 10 verification: `flutter analyze` passed; `flutter test` passed (119
tests); `flutter build web --release` passed. The preparation widget test
covers narrow-screen rendering and adding an eligible registered player.

## Remaining scope

Points 11-29 remain incomplete: live auction
and bidding; projector,
team-owner and public live views; sold/unsold administration; results and
analytics; user administration; notifications; audit and transaction ledger;
file-based CSV/Excel/PDF exchange; offline/LAN mode; cloud backend; payments;
backup/restore; white-label; and support/settings expansion.

## Persistence and security

Current auction/team/player repositories are local in-memory implementations.
Purse accounts and adjustment history are also local in-memory data. None of
these records survive app restarts. Demo authentication and role checks are not
production security; trusted server-side authorization and database policies
are required before release.

Auction rule sets are also in-memory. Bid increment selection/next-bid
calculation is implemented as domain logic, but no live bidding workflow
consumes it. Timer, ordering, category/overseas/wicketkeeper limits, and
unsold-player re-entry are configuration only; reusable domain validation
checks prospective squad additions, but Point 9 deliberately does not create
player assignments, purchases, purse deductions, or auction transactions.
Existing sold-and-assigned player records with a positive purchase price are
used to calculate spend; missing/invalid prices are surfaced as warnings and
never fabricated.

Auction preparation queues are also in-memory and volatile. Queue contents
are scoped by auction ID and queue mutations are serialized within the local
repository, but they do not synchronize across devices or survive app
restarts. The readiness checklist validates configured rules, at least two
active teams, and a non-empty queue of eligible registered players; profile
review warnings are non-blocking. Preparation does not start bidding or create
purchase transactions.
