# JP AUCTION ARENA — Feature Roadmap

## Product direction

JP AUCTION ARENA is a cricket player auction management application, not a
general tournament administration system. Auctions are the product's root
aggregate: each auction will own its team registrations, player registrations,
purse configuration, rules, bid history, transactions, and results.

The previous tournament-management implementation is retained in source and
its legacy URL redirects to Auctions, but it is no longer the product's primary
workflow. Do not extend it as a general tournament module. Existing demo team
and player screens are not yet associated with auction IDs and are not linked
from auction details.

Do not claim a future service is operational until implemented and tested.
Points 1-4 establish the blueprint, Flutter foundation, demo authentication,
roles, dashboard, and responsive navigation. Point 5 is auction creation and
management. Stop after Point 5 and wait for approval before Point 6.

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
- No extra dependencies or external services are introduced by Point 5.

## CI failure remediation

The supplied GitHub Actions run failed because baseline tests imported absent
tournament/team/player models and repositories. Minimal in-memory contracts,
models, and screens were added so those tests could compile. Those recovered
team/player records remain demo foundations; they are not yet auction-scoped
and must not be presented as complete auction registration.

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
  Auction team/player registration, bid rules, live bidding, transaction
  history, cloud persistence, and server-side authorization are not implemented.

## Proposed future sequence — approval required

| Point | Scope | Key exit criteria |
|---|---|---|
| 6 — Auction team/player registration and settings | Auction-scoped team/player registration, purse allocations, player profiles, base prices, increments, squad/category rules, setup readiness | Every record scoped by auction ID; capacity and purse rules tested; import/export boundaries |
| 7 — Trusted identity and persistence | Supabase Authentication/PostgreSQL and trusted authorization; Node.js API only where needed | Server-side role/auction isolation; durable migration and recovery design |
| 8 — Live auction engine | Operator control room, bid/session state, player outcomes, append-only transactions and audit | Concurrency, single-live/session, purse consistency, reconnect and replay tests |
| 9 — Auction displays, team view, results and reports | Projector/public read-only screens, assigned-team view, results and analytics | All views derived from the same authoritative auction transaction state |
| 10 — Offline/LAN mode | SQLite cache and WebSocket local network mode | Single authority, durable event log, replay and cloud reconciliation |
| 11 — Administration and operations | Notifications, audit, backup/restore, subscriptions/payments, white-label | Security, retention, entitlements, provider and recovery design |
| 12 — Data exchange and hardening | CSV/Excel and future CricHeroes compatibility, accessibility and platform QA | Stable contracts and tested mappings; no compatibility claims before verification |

## Deferred capability coverage

Multiple auction formats and currencies, configurable base prices, bid
increments, team purse and squad/category limits, player profiles/statistics,
projector mode, mobile team dashboard, offline/LAN operation, analytics, audit,
backup/recovery, white-label branding, subscriptions/payments, secure
role-based access, Supabase/PostgreSQL, Node.js business logic, Supabase
Realtime, CSV/Excel, and future CricHeroes compatibility are reserved. Only
capabilities described as implemented under Points 1-5 are available now.

## Approval gate

Point 5 is complete. Stop and obtain explicit user approval before starting
Point 6. Do not start team/player auction registration or live bidding without
that approval.
