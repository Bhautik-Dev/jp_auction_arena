# JP AUCTION ARENA — Feature Roadmap

## Product direction

JP AUCTION ARENA is a cricket player auction management application, not a
general tournament administration system. Auctions are the product's root
aggregate: each auction will own its team registrations, player registrations,
purse configuration, rules, bid history, transactions, and results.

The previous tournament-management implementation is retained in source and
its legacy URL redirects to Auctions, but it is no longer the product's primary
workflow. Do not extend it as a general tournament module. Legacy demo team
and player records remain separate from auction registrations.

Do not claim a future service is operational until implemented and tested.
Points 1-4 establish the blueprint, Flutter foundation, demo authentication,
roles, dashboard, and responsive navigation. Point 5 is auction creation and
management. Points 6-7 establish auction-scoped team and player registrations.
Point 8 adds per-auction bid increment rules and their settings editor. Point 9
adds read-only purse/squad tracking and reusable validation; it does not
implement bidding or create sold-player transactions.

## Point 1 — Product blueprint

**Status: completed and updated to auction-first direction.**

- Defines the cricket-auction architecture, roles, permissions, data boundaries,
  screen groups, navigation, invariants, and future service plan.
- Auctions have independent identities; team/player registrations and
  transaction data must never cross auction boundaries.
- Preserves the shared Material 3 JP AUCTION ARENA design system and the
  one-live-auction, immutable-history, role-scope, and audit requirements.

## Point 2 — Project foundation

**Status: implemented.**

- Flutter, Riverpod, GoRouter, feature-based layers, shared components,
  responsive shell, and branded Material 3 theme are in place.
- No extra dependencies or external services were introduced by Points 5-7.

## CI failure remediation

The supplied GitHub Actions run failed because baseline tests imported absent
tournament/team/player models and repositories. Minimal in-memory contracts,
models, and screens were added so those tests could compile. Those recovered
player records remain demo foundations. Legacy team fixtures remain for
compatibility; new team registrations are auction-scoped.

## Point 3 — Authentication and roles

**Status: demo/local foundation implemented.**

- Demo sign-in, session state, route guards, role/permission definitions,
  logout, and unauthorized/loading screens are implemented.
- Super Admin and Tournament Admin / Auction Operator can manage auctions.
  Operators are scoped to assigned auction IDs. Team Managers and Public
  Viewers cannot create or control auctions.
- Demo credentials are synthetic and not production accounts. Authorization is
  client-side only; trusted backend and database policies remain future work.

## Point 4 — Dashboard and navigation

**Status: implemented and now auction-first.**

- Role-aware dashboard summarizes auction records and provides a prominent
  **CREATE NEW AUCTION** action for authorized admins/operators.
- Team and public roles receive read-only views. The team demo record is
  explicitly identified as not yet associated with an auction.
- The responsive shell's primary feature destination is Auctions. The legacy
  tournament URL redirects to Auctions.

## Point 5 — Auction creation and management

**Status: implemented locally; see known limits below.**

- Auction list, create/edit, details, settings, and completed/archive history.
- Fields include name, optional logo reference/description/location, date and
  start time, auction type, cricket format, team/squad limits, purse/currency,
  status, organizer, and optional contact.
- Domain validation covers required fields, past dates, time bounds, team and
  squad limits, positive finite purse, currency code, and custom formats.
- Lifecycle supports Draft → Ready → Live ↔ Paused → Completed → Archived;
  archived auctions can be restored to Completed. Only one auction may be
  Live. Live, paused, completed, and archived records cannot be edited.
- Role checks and operator auction assignment are enforced in the application
  service. The repository independently enforces lifecycle and single-live
  invariants. Completed records are retained; no delete operation exists.
- Storage is in-memory and volatile. Seed records are labelled demo data.
  Bid rules, live bidding, transaction history, cloud persistence, and
  server-side authorization are not implemented.

## Point 6 — Team management and registration

**Status: implemented locally; backend persistence and file-based exchange remain
future work.**

- Added auction-linked team identity, logo reference, short name, owner/manager,
  contacts, city, description, and Active/Inactive/Archived statuses.
- Added auction-specific list/search/status filter, registration/edit/details,
  archive/restore, and team CSV paste-import/clipboard-export.
- Domain service enforces manage-team permissions, operator auction assignment,
  auction availability, archived read-only behavior, and live-auction mutation
  lock. Repository enforces auction capacity, same-auction uniqueness, and
  auction isolation; bulk CSV validation occurs before writes.
- Team purse and squad constraints are displayed from the parent auction and
  are not duplicated on each team record.
- Legacy tournament demo teams remain available for compatibility and the
  demo team dashboard; they are excluded from auction registration lists.
- Image upload, durable storage, Excel/file-based import/export, and
  server-authoritative authorization are not implemented.

## Point 7 — Player management and auction-scoped registration

**Status: implemented locally; durable storage, file-based exchange, and
auction execution remain future work.**

- Added auction ID and optional image reference to player registration while
  retaining unscoped legacy fixtures for compatibility.
- Added player list/search/category/status filters; create/edit forms; player
  details and statistics; Available/Unavailable controls; and safe deletion
  rules that retain Sold/Unsold results and team-assigned records.
- Added domain-service role, assigned-auction, auction-existence, lifecycle,
  and cross-auction team-assignment checks. Player registration and profile
  changes are restricted to Draft/Ready auctions; auction outcomes cannot be
  changed in this module.
- Added atomic CSV paste-import and clipboard export. Repository writes are
  serialized, names are unique within an auction, and every new registration
  is scoped to one auction.
- Added auction detail registration counts/links and dashboard counts derived
  from accessible auction registrations. Team and public roles do not receive
  the private player-management list.
- Image upload, file downloads, Excel/PDF support, durable persistence,
  Supabase, and server-authoritative authorization are not implemented.

## Point 8 — Auction configuration and rule engine

**Status: configuration and domain validation implemented locally; live
execution remains future work.**

- Added per-auction fixed and tiered bid increments. Tiers support optional
  inclusive maximums, reject invalid/overlapping ranges, and calculate the
  increment and next valid bid. Fixed increments and tier boundaries are
  covered by unit tests.
- Added rule validation for positive purse/base prices, squad ordering,
  category caps, optional overseas/wicketkeeper caps, timer/warning/extension
  bounds, and unsold re-entry limits. Existing auction fields remain the source
  for auction format/type, currency, team purse, and min/max squad size.
- Added optional default and category-specific player base prices. Player
  registration suggests the configured category/default value; the player
  service enforces positive base prices that do not exceed the auction purse.
- Added player order selection, bid timer and extension settings, category
  limits, optional overseas/wicketkeeper limits, and unsold re-entry controls.
- The responsive settings editor provides loading/error states, readable
  summaries, and Save/Cancel. Auction Details show the saved rule summary.
- Super Admin and assigned Tournament Admin / Auction Operator access is
  enforced in the rule service. Rule writes are limited to Draft and Ready
  auctions. Rules are isolated by auction ID and stored in memory.
- Timer execution, player sequencing, actual purchase assignment, purse
  deductions, live bidding, transactions, and durable persistence are not
  implemented.
- Verification on this checkout: `flutter analyze` passed; `flutter test`
  passed (108 tests); `flutter build web --release` passed; `git diff --check`
  passed.

## Point 9 — Team purse and squad management

**Status: implemented locally; player purchases and durable persistence remain
future work.**

- Added auction/team-keyed purse accounts. The default initial purse is loaded
  from that auction's purse setting; spent totals derive only from sold players
  assigned to that team with a positive recorded purchase price. Remaining
  purse is initial purse plus append-only adjustments minus recorded spend.
- Added admin/operator adjustments with required reason, actor, and timestamp.
  Repository-serialized writes enforce that the adjusted purse cannot fall
  below recorded spend. Adjustments are read-only after an auction becomes
  Live.
- Added team purse/squad summaries with category counts, remaining slots,
  minimum/maximum and configured category/overseas/wicketkeeper warnings,
  player profiles, prices, and incomplete-price warnings. Missing or invalid
  prices are not fabricated.
- Added reusable domain purchase validation for auction/team scope, unique
  player registration, available/unassigned status, positive price, remaining
  purse, max squad size, and configured category/overseas/wicketkeeper limits.
  This validator records no purchase and does not change player status,
  assignments, or purse balances.
- Added a responsive read-only Team Manager portal restricted to assigned
  auction teams, plus admin/operator purse and squad details in team detail.
  Overseas classification can be maintained on eligible player profiles and
  imported/exported as an optional `is_overseas` CSV column.
- Purchases, purse deductions, transaction history, team-owned account
  assignment workflows, persistent storage, public purse visibility, and
  server-authoritative authorization remain out of scope.
- Verification on this checkout: `flutter analyze` passed; `flutter test`
  passed (108 tests); `flutter build web --release` passed; `git diff --check`
  passed.

## Remaining agreed points

| Point | Scope | Current status |
|---|---|---|
| 9 | Team purse and squad management | Implemented locally; no purchase transactions |
| 10 | Auction preparation and player order | Not started |
| 11-12 | Live auction control room and bidding engine | Not started |
| 13-15 | Projector, team-owner mobile, and public live views | Not started |
| 16-19 | Sold/unsold, results, reports, and auction history | Not started |
| 20-23 | User administration, notifications, audit, and data exchange | Not started |
| 24-29 | Offline/LAN, backend readiness, subscriptions, backup, branding, settings/support | Not started |

## Deferred capability coverage

Multiple auction formats and currencies, configurable base prices, bid
increments, team purse and squad/category limits, player profiles/statistics,
projector mode, mobile team dashboard, offline/LAN operation, analytics, audit,
backup/recovery, white-label branding, subscriptions/payments, secure
role-based access, Supabase/PostgreSQL, Node.js business logic, Supabase
Realtime, Excel, and future CricHeroes compatibility are reserved. Only
capabilities described under Points 1-9 are available locally as described
above; deferred services remain unavailable until separately implemented and
tested.
