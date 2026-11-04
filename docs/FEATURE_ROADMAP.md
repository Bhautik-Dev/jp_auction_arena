# JP AUCTION ARENA — Feature Roadmap

## Roadmap rules

- The agreed product direction and requirements in
  [APP_BLUEPRINT.md](./APP_BLUEPRINT.md) remain the source of truth.
- Deliver modules in dependency order, preserving a unified navigation and
  design system.
- Do not describe planned services as operational until implemented and tested.
- Point 1 was documentation and scope definition only. Point 2 is complete;
  Point 3 and later work require explicit approval.

## Point 1 — Complete app blueprint, requirements, and navigation flow

**Status: completed.**

- Define architecture, modules, all 32 requested screens, navigation, roles,
  permissions, logical data entities, invariants, and future integration
  boundaries.
- Preserve the one-active-tournament rule, completed tournament archives,
  team purse/squad limits, role-based auction control, audit history, and
  consistent live state as mandatory design requirements.
- Do not add feature modules, implement live auction, or integrate Supabase,
  Node.js, authentication providers, realtime services, or payments in this
  point.

## Point 2 — Project foundation and global app structure

**Status: foundation implemented; feature modules intentionally not started.**

- Added the app composition root, Material 3 brand themes, responsive shell,
  Riverpod theme state, GoRouter destinations, shared widgets, and foundation
  tests.
- Dashboard and application settings are available. Planned tournament, team,
  player, auction, results, reports, and history destinations are visibly
  marked as coming soon and contain no feature business logic.
- No external services or dependencies were added.
- Tournament/team/player implementation remains a known gap from the inspected
  baseline and is not restored or reimplemented in Point 2.
- Focused foundation tests and the Web build pass. Repository-wide analysis and
  the full test suite remain blocked by existing tests importing the absent
  tournament/team/player feature source files.

## Baseline inspection and conflicts

The manifest declares Flutter/Dart with Riverpod and GoRouter. Before Point 2,
the tracked `lib/` tree contained only `lib/main.dart`, which imported a missing
`lib/app.dart`. The Point 2 work adds the foundation entry and shared app
structure. Existing tests still refer to absent tournament/team/player
implementations and describe intended earlier behavior:

- Responsive compact and wide navigation, dark/light branded themes, dashboard
  navigation, and the tournament/team/player screens.
- Tournament model duration, copy/serialization, lifecycle helpers, seeded
  data, filtering, and CRUD/status operations.
- Team CRUD, per-tournament unique team names/short names, tournament capacity,
  status/search filtering, and deletion safeguards for history/assignments.
- Player CRUD, filtering, positive base-price/name validation, optional contact
  and team assignment, and unknown-team assignment rejection.

**Conflict found:** tournament, team, and player source files referenced by
the existing test suite are absent from the tracked baseline. Their intended
behavior is not claimed as working and has not been restored or reimplemented
in Point 2. Foundation-specific tests were updated to verify only the current
shell and implemented destinations.

The manifest's current state management and navigation dependencies match the
target direction. No checked-in evidence in the inspected source confirms
completed authentication, backend, database, payments, or realtime
integration. These remain future work.

## Proposed implementation sequence (future work; approval required)

| Phase | Scope | Prerequisites / exit criteria |
|---|---|---|
| Point 3 — Tournament, team, and player foundation | Implement domain contracts, validation, in-memory/local repositories as appropriate, list/detail/forms, tournament lifecycle, team capacity, player registration, and import/export boundaries | Foundation; test core entity and lifecycle invariants |
| Point 4 — Auction setup and pre-check | Support auction formats, configurable base prices, increments, rules, purses, squad/category limits, and blocking readiness checks | Tournament/team/player foundation; test constraints and one-active invariant |
| Point 5 — Trusted identity and cloud persistence | Design and implement Supabase authentication/PostgreSQL access policies; add Node.js API only where trusted business logic requires it | Approved security/data design; role and tournament scoping tests |
| Point 6 — Live auction engine and displays | Implement authoritative bid/session transactions, control room, projector, assigned team view, and public read-only view; synchronize clients | Point 4 and trusted command boundary; concurrency, audit, reconnect, and purse consistency tests |
| Point 7 — Results, reports, history, audit, and recovery | Derive results from transactions; reports/analytics; archives; audit logs; backup and restore workflows | Durable authoritative transaction/event data |
| Point 8 — Offline/LAN mode | SQLite mobile cache and WebSocket local network mode with explicit authority, replay, and reconciliation | Defined offline consistency and recovery model |
| Point 9 — Subscription, payment, and white-label | Entitlements, subscription plans/payments, tenant branding | Provider/security/privacy design and deployment needs |
| Point 10 — External data compatibility and hardening | CSV/Excel completion, future CricHeroes mapping, cross-platform QA, accessibility, operational monitoring | Stable data contracts and regression coverage |

Phase names and order beyond Point 1 are a planning proposal, not a commitment
to start work. In particular, Live Auction implementation begins only in its
approved future phase.

## Future capability coverage

| Capability | Planned home | Status |
|---|---|---|
| Multiple auction formats | Auction setup / live auction | Reserved; not implemented |
| Configurable base prices | Player registration / auction setup | Reserved; not implemented |
| Bid increments and auction rules | Auction setup | Reserved; not implemented |
| Team purse management | Team management / auction setup | Reserved; not implemented |
| Squad size and category limits | Team management / auction setup | Reserved; not implemented |
| Player statistics and profiles | Player management / reporting | Reserved; not implemented in current source |
| Live auction projector mode | Public display | Reserved; not implemented |
| Mobile team dashboard | Team portal | Reserved; not implemented |
| Offline and local network auction mode | Local data / live auction | Reserved; no SQLite or WebSocket integration |
| Reports and analytics | Results and reporting | Reserved; not implemented |
| Audit logs and transaction history | Administration / live auction | Reserved; not implemented |
| Backup and recovery | Administration | Reserved; not implemented |
| White-label branding | Settings / administration | Reserved; not implemented |
| Subscription plans and payments | Administration | Later phase; no payment integration |
| Secure role-based access | Identity/access and backend policy | Requirement reserved; no authentication service integrated |
| Supabase/PostgreSQL | Cloud data/auth | Future plan; not integrated |
| Node.js business API | Trusted backend logic | Future option; not integrated |
| Supabase Realtime | Cloud synchronization | Future plan; not integrated |
| CSV/Excel interchange | Import/export | Required future support; inspect current implementation after baseline recovery |
| CricHeroes compatibility | Import/export adapter | Future compatibility goal; not integrated or guaranteed |

## Approval gate

Point 2 is complete. Stop here and obtain explicit user approval before
starting Point 3.
