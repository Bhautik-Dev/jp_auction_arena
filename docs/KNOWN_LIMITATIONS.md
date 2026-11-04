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
- Team purse and squad limits are inherited and displayed from the parent
  auction. Team-level purse usage, player assignment, and squad tracking await
  later points.
- Player auction registration, auction rules, live bidding, transaction and
  audit ledgers, public/team live screens, and reports are not implemented.
- Supabase, PostgreSQL, Node.js, Realtime, payments, push notifications,
  SQLite, and local-network synchronization are not connected.
