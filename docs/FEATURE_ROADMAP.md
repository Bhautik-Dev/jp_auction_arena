# JP AUCTION ARENA — Feature Roadmap

## Roadmap rules

- The agreed product direction and requirements in
  [APP_BLUEPRINT.md](./APP_BLUEPRINT.md) remain the source of truth.
- Deliver modules in dependency order, preserving a unified navigation and
  design system.
- Do not describe planned services as operational until implemented and tested.
- Point 1 is documentation and scope definition only. This file does not start
  Point 2 or authorize implementation of the live auction.

## Point 1 — Complete app blueprint, requirements, and navigation flow

**Status: documentation prepared; implementation intentionally not started.**

- Define architecture, modules, all 32 requested screens, navigation, roles,
  permissions, logical data entities, invariants, and future integration
  boundaries.
- Preserve the one-active-tournament rule, completed tournament archives,
  team purse/squad limits, role-based auction control, audit history, and
  consistent live state as mandatory design requirements.
- Do not add feature modules, implement live auction, or integrate Supabase,
  Node.js, authentication providers, realtime services, or payments in this
  point.
- Wait for explicit approval before starting Point 2.

## Baseline inspection and conflicts

The manifest declares Flutter/Dart with Riverpod and GoRouter. The README
describes a Material 3 theme, responsive navigation shell, dashboard
placeholder, and in-memory tournament screens. Existing tests refer to the
following earlier implementation behavior:

- Responsive compact and wide navigation, dark/light branded themes, dashboard
  navigation, and the tournament/team/player screens.
- Tournament model duration, copy/serialization, lifecycle helpers, seeded
  data, filtering, and CRUD/status operations.
- Team CRUD, per-tournament unique team names/short names, tournament capacity,
  status/search filtering, and deletion safeguards for history/assignments.
- Player CRUD, filtering, positive base-price/name validation, optional contact
  and team assignment, and unknown-team assignment rejection.

**Conflict found:** in the inspected worktree, `lib/` contains only
`lib/main.dart`; it imports the missing `lib/app.dart`. The application,
router, theme, tournament, team, and player source files referenced by the
README and tests are absent from the tracked tree. The tests also import those
missing files. Thus the repository's README and test suite describe intended
or previously implemented functionality that is not present in the current
tracked source snapshot. No source was restored or rewritten for Point 1.

The manifest's current state management and navigation dependencies match the
target direction. No checked-in evidence in the inspected source confirms
completed authentication, backend, database, payments, or realtime
integration. These remain future work.

## Proposed implementation sequence (future work; approval required)

| Phase | Scope | Prerequisites / exit criteria |
|---|---|---|
| Point 2 — Foundation and baseline recovery | Confirm the intended source baseline; restore or recreate only with approval; establish shared theme, responsive shell, route structure, Riverpod conventions, and passing app smoke tests | Resolve the missing-source conflict; preserve agreed product scope |
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

Stop after Point 1. Obtain explicit user approval before starting Point 2.
