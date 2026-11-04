# JP AUCTION ARENA — Feature Roadmap

## Roadmap rules

- The agreed product direction and requirements in
  [APP_BLUEPRINT.md](./APP_BLUEPRINT.md) remain the source of truth.
- Deliver modules in dependency order, preserving a unified navigation and
  design system.
- Do not describe planned services as operational until implemented and tested.
- Points 1-4 are complete. Point 5 and later work require explicit approval.

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

**Status: foundation implemented.**

- Added the app composition root, Material 3 brand themes, responsive shell,
  Riverpod theme state, GoRouter destinations, shared widgets, and foundation
  tests.
- Application settings are available; Point 4 adds the role-aware dashboard
  experience. Feature modules remain separate from the foundation.
- No external services or dependencies were added.
- Focused foundation tests and the Web build pass. Repository-wide analysis and
  the full test suite initially exposed absent tournament/team/player feature
  files from the inspected baseline.

## CI failure remediation

The supplied GitHub Actions run (run 41748477076, commit
`4346cdbee1ddd304334ba12b3235061fcf280de6`) failed in **Run Tests** because
the tracked tree lacked tournament, team, and player source files imported by
the existing tests. The Web build and deployment steps were skipped. To
resolve that compile-time failure, this follow-up restored minimal domain
models, repository contracts and in-memory implementations, Riverpod providers,
and the list/player registration/detail screens exercised by those tests.
The full test suite and analyzer now pass locally.

This is limited feature-foundation recovery for the CI failure, not completion
of the full tournament/team/player feature scope. Tournament create/edit, team
registration, auction setup/control, persistence, and remote integrations
remain unimplemented.

## Point 3 — Authentication and user role management

**Status: demo/local authentication and client access foundation implemented.**

- Added login, forgot-password, session-loading, unauthorized, team-portal, and
  public-view routes/screens using the shared theme and GoRouter.
- Added an `AuthRepository` contract, in-memory demo implementation, Riverpod
  session controller, centralized role/permission definitions, assignment
  checks, route guards, role landing routes, and confirmed logout.
- Synthetic credentials are listed in the README. They are demonstration
  values, not real accounts. Password reset and persistent sessions are not
  available in the local demo. No external authentication or Supabase service
  is connected.
- Route guards are a client-side UX/access foundation; they are not a security
  boundary. Production authorization must also be enforced by trusted backend
  and database policies.
- No auction setup or live-auction functionality was implemented.

## Point 4 — Dashboard and main navigation experience

**Status: role-adaptive dashboard and responsive navigation implemented.**

- Added dedicated Super Admin, Tournament Admin / Auction Operator, Team
  Owner / Team Manager, and Public Viewer dashboard layouts using the shared
  design system.
- Added reusable statistic, quick-action, recent-activity, notification,
  tournament overview, team overview, progress, and demo-data widgets. Shared
  loading, error, and empty states are used for asynchronous data.
- Added a dashboard repository contract and Riverpod provider. The demo
  implementation composes existing in-memory tournament, team, and player
  repositories; role scopes limit returned tournament/team summaries.
- All displayed sample records are marked as synthetic demo data. Auction
  readiness, team purse examples, recent activity, and notifications are
  illustrative or unavailable—not live data. Tournament/player association
  and purse transactions are not modeled yet.
- All roles now land on the role-aware dashboard. Shell destinations and
  dashboard quick actions are checked against the existing route access
  policy; team and public views expose no administrative actions.
- No tournament/team/player management logic, auction setup, live auction, or
  external services were added.

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

**Baseline gap addressed:** tournament, team, and player source files were
absent from the tracked baseline. A limited set of these files has now been
added to make the existing model, repository, and widget tests compile and
pass. Remaining functionality must be implemented in the approved feature
phases.

The manifest's current state management and navigation dependencies match the
target direction. Point 3 provides only local demo authentication and
client-side guards; no backend, persistent database, production authentication,
payments, or realtime integration is present.

## Proposed implementation sequence (future work; approval required)

| Phase | Scope | Prerequisites / exit criteria |
|---|---|---|
| Point 5 — Tournament, team, and player management | Complete domain workflows, tournament lifecycle, team capacity, player registration, and import/export boundaries | Auth role foundation; test core entity and lifecycle invariants |
| Point 6 — Auction setup and pre-check | Support auction formats, configurable base prices, increments, rules, purses, squad/category limits, and blocking readiness checks | Tournament/team/player management; test constraints and one-active invariant |
| Point 7 — Trusted identity and cloud persistence | Replace demo auth with Supabase Authentication/PostgreSQL access policies; add Node.js API only where trusted business logic requires it | Approved security/data design; role and tournament scoping tests |
| Point 8 — Live auction engine and displays | Implement authoritative bid/session transactions, control room, projector, assigned team view, and public read-only view; synchronize clients | Point 6 and trusted command boundary; concurrency, audit, reconnect, and purse consistency tests |
| Point 9 — Results, reports, history, audit, and recovery | Derive results from transactions; reports/analytics; archives; audit logs; backup and restore workflows | Durable authoritative transaction/event data |
| Point 10 — Offline/LAN mode | SQLite mobile cache and WebSocket local network mode with explicit authority, replay, and reconciliation | Defined offline consistency and recovery model |
| Point 11 — Subscription, payment, and white-label | Entitlements, subscription plans/payments, tenant branding | Provider/security/privacy design and deployment needs |
| Point 12 — External data compatibility and hardening | CSV/Excel completion, future CricHeroes mapping, cross-platform QA, accessibility, operational monitoring | Stable data contracts and regression coverage |

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
| Mobile team dashboard | Role-specific dashboard / team portal | Demo UI implemented; live purse and auction data unavailable |
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

Point 4 is complete. Stop here and obtain explicit user approval before
starting Point 5.
