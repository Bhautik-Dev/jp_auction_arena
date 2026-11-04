# Known Limitations

- Auction and team data use volatile in-memory repositories and are lost when
  the app process ends.
- Authentication and authorization are local demo implementations. Route and
  domain-service checks do not replace trusted backend authorization.
- Existing tournament code and unscoped demo team/player records remain for
  compatibility; they are not auction registrations.
- Team logo/image values are references only; upload and storage are not
  implemented.
- Team CSV import requires pasted CSV text. Export copies CSV text to the
  clipboard. File downloads, file selection, Excel, and PDF are not included.
- Player CSV import requires pasted CSV text. Export copies CSV text to the
  clipboard. Player image fields are references only; no upload or storage is
  implemented.
- Team purse and squad limits are inherited and displayed from the parent
  auction. Team-level purse usage, player assignment, and squad tracking await
  later points.
- Player registrations are auction-scoped but are volatile in-memory records.
  Player team assignment and Sold/Unsold result operations are intentionally
  not part of player management and await later auction phases.
- Bid increment tiers can be configured per auction and their selection/next
  bid can be calculated by the domain rule engine. Rule sets are volatile
  in-memory data and are not consumed by live bidding, which is not implemented.
- Unsold-player re-entry is a stored preference only; auction rounds and
  re-entry behavior are not implemented.
- Purse/squad enforcement, auction preparation checks, transaction and audit
  ledgers, public/team live screens, and reports are not implemented.
- Supabase, PostgreSQL, Node.js, Realtime, payments, push notifications,
  SQLite, and local-network synchronization are not connected.
