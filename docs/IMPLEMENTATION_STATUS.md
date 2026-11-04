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

## Remaining scope

Points 7-29 remain incomplete: auction-scoped player registration; auction
rules and preparation; purse/squad tracking; live auction and bidding; projector,
team-owner and public live views; sold/unsold administration; results and
analytics; user administration; notifications; audit and transaction ledger;
file-based CSV/Excel/PDF exchange; offline/LAN mode; cloud backend; payments;
backup/restore; white-label; and support/settings expansion.

## Persistence and security

Current auction/team repositories are local in-memory implementations. Data
does not survive app restarts. Demo authentication and role checks are not
production security; trusted server-side authorization and database policies
are required before release.
