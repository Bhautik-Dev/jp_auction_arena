# JP AUCTION ARENA — Navigation Flow

This is the target navigation map for the approved product scope. Points 3-5
implement local demo login, role-aware route guards, the dashboard, and
tournament management; other destinations remain conceptual until their
feature phases.
The shared app shell and role-aware access rules apply to signed-in modules; a
navigation destination never grants permission by itself.

## 1. Entry and access flow

```mermaid
flowchart TD
    A[App launch] --> B[Splash Screen]
    B --> C{First run?}
    C -- Yes --> D[Onboarding / App Introduction]
    C -- No --> E{Session available?}
    D --> E
    E -- No --> F[Login]
    F --> G[Forgot Password]
    G --> F
    F --> H{Authenticated and authorized?}
    E -- Yes --> H
    H -- No --> F
    H -- Yes --> I[Role-aware Dashboard]
    P[Public live link] --> Q[Public Live Auction View: read-only]
```

An authenticated user's role and tournament/team assignments determine the
dashboard shortcuts and accessible routes. A public live link is separate from
the admin shell, is read-only, and exposes only explicitly published fields.
The current Point 3 login uses in-memory demo accounts only; it is not
production authentication. All roles land on the dashboard, whose content and
quick navigation are scoped by role. Team Managers can continue to their
assigned-team view; Public Viewers can open the separate read-only public live
view.

## 2. Signed-in shell and feature navigation

```mermaid
flowchart LR
    D[Dashboard] --> T[Tournament Management]
    D --> N[Notifications]
    D --> S[Application Settings]
    D --> H[Help and Support]

    T --> TL[Tournament List]
    TL --> CE[Create / Edit Tournament]
    TL --> TD[Tournament Details]
    TL --> TH[Tournament History / Archives]
    TD --> SM[Tournament Status Management]
    TD --> TM[Team Management]
    TD --> PM[Player Management]
    TD --> AC[Auction Configuration]
    TD --> TR[Tournament Reports and Statistics]
    TM --> TRG[Team Registration]
    TM --> TDT[Team Details]
    TM --> PS[Team Purse and Squad Configuration]
    PM --> PR[Player Registration]
    PM --> PDT[Player Details]
    PM --> IE[Player Import / Export]
    AC --> AR[Auction Rules and Bid Increments]
    AC --> PRE[Auction Pre-check / Ready]
    PS --> PRE
    PR --> PRE
    PRE --> LC[Live Auction Control Room]
    LC --> PD[Live Auction Projector Display]
    LC --> TV[Team Mobile View]
    LC --> PV[Public Live Auction View]
    LC --> SU[Sold / Unsold Player Management]
    SU --> R[Auction Results]
    R --> TR
    TH --> TD

    D --> UA[User and Role Management]
    D --> SUB[Subscription and Payment Management]
    D --> AL[Audit Logs]
    D --> BR[Backup and Restore]
```

The diagram presents relationships, not the permission to enter every
destination. Implemented tournament routes are list/search/filter, create/edit,
details, lifecycle status management, and completed/archive history. Creation,
editing, activation, completion, archive/restore, and deletion are subject to
role/assignment and lifecycle rules; archived tournaments are read-only until
an authorized restore. Only one tournament may be active. A Team Owner's Team
Mobile View is restricted to the assigned team and is read-only for auction
activity. Projector and public views cannot navigate into control functions.
Team and player destinations shown above are planned, not implemented.

## 3. Tournament lifecycle sequence

1. **Dashboard → Tournament Management → Tournament List.** Search by name,
   filter by status, sort by date, and open tournament details or history.
2. **Create / Edit Tournament.** Enter identity/description, location,
   tournament and registration dates, format, team capacity, squad limits,
   organizer/contact, and notes. New tournaments start as Draft or Upcoming;
   logo/image is currently a placeholder/reference.
3. **Tournament Details → Status Management.** Authorized Super Admins and
   assigned Tournament Admins manage the lifecycle. Activation is rejected if
   another tournament is active. Completion and archive preserve the record;
   archived records are read-only until restored. In-memory data is volatile.
4. **Team Management → Team Registration → Team Details.** Register teams,
   owners/managers, and tournament-specific configuration.
5. **Player Management → Player Registration → Player Details.** Register
   player profiles for the tournament, categorize them, set base-price
   eligibility, and manage data import/export.
6. **Auction Configuration → Auction Rules and Bid Increments.** Select the
   auction format and define prices, increments, squad/category constraints,
   and auction rules.
7. **Team Purse and Squad Configuration.** Configure each team's purse and
   limits. Validate all team settings against the tournament configuration.
8. **Auction Pre-check / Ready Screen.** Show blocking issues and confirmations
   before opening a session (for example missing team setup, invalid limits, or
   unregistered players).
9. **Live Auction Control Room.** Authorized operator starts and controls the
   live session. It publishes state to read-only projector, assigned team, and
   public views.
10. **Sold / Unsold Player Management → Auction Results.** Resolve remaining
    players and review final squads and immutable transaction history.
11. **Tournament Reports and Statistics → Tournament History / Archives.**
    Produce and retain tournament summaries and exports.

Steps 4-11 are planned future flows. Current tournament management does not
implement team/player workflows, auction setup/operations, reports, or durable
storage.

## 4. Live auction navigation and state flow

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Configured: rules, teams, players, limits valid
    Configured --> Ready: pre-check passes
    Ready --> Live: authorized operator starts
    Live --> Live: authorized bid/lot action
    Live --> Paused: authorized operator pauses
    Paused --> Live: authorized operator resumes
    Live --> Resolved: each lot sold / unsold / unavailable
    Resolved --> Completed: authorized operator closes session
    Completed --> Archived: tournament is completed and archived
```

For each player lot, the authoritative transition is:

```text
remaining/available -> sold(team, final price)
                    -> unsold
                    -> unavailable(reason, where required)
```

Only one terminal outcome may be committed for a lot. A sale updates the
player's tournament registration, team roster, purse ledger, transaction
history, and audit event atomically (or through a designed transactional
workflow with equivalent recovery guarantees). Public and team screens consume
the resulting state; they do not issue commands. Realtime delivery may be
delayed, so clients must reconcile against authoritative state after reconnect.

## 5. Role-aware navigation summary

| Role | Primary navigation | Restricted destinations/actions |
|---|---|---|
| Super Admin | All modules, all tournaments, administration | No product restriction beyond safeguards and auditability |
| Tournament Admin / Auction Operator | Assigned tournament dashboard, tournament/team/player setup, auction setup/control, results and reports | User/global role management, global subscriptions, backups, or other tournaments unless separately granted |
| Team Owner / Team Manager | Assigned team's mobile view, purse/squad, published progress/results, notifications, help/settings | No bidding, auction start/pause/resolve, other teams' private data, tournament configuration |
| Public Viewer | Published public live view, projector output, published results | No sign-in-only/private data, edits, commands, bids, or control room |

Detailed action permissions and invariants are in
[APP_BLUEPRINT.md](./APP_BLUEPRINT.md#user-roles-and-permissions).

## 6. Navigation and access behavior

- Preserve the selected tournament context while navigating among its teams,
  players, setup, auction, and reports.
- Keep list → detail → edit flows reversible with clear back navigation and
  unsaved-change confirmation.
- Scope shell destinations by role and assignment. Deep links must repeat
  authorization checks, including after a session change.
- Treat live control and live display as distinct route families/layouts; do
  not expose operator controls in team or public views.
- Open projector mode in a presentation-friendly route without changing
  authoritative auction state.
- Use a single shared responsive navigation shell for ordinary app modules.
  Adapt its presentation for Web/Windows wide layouts and mobile touch layouts.
- Provide clear loading, empty, permission-denied, offline, and recoverable
  connection states. Do not present stale data as live-confirmed.
- Keep public routes limited to published tournament and auction fields.

## 7. Route inventory cross-reference

The complete 32-screen inventory, grouped by product module and primary access
role, is maintained in [APP_BLUEPRINT.md](./APP_BLUEPRINT.md#complete-screen-inventory).
