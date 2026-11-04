enum AppRole {
  superAdmin,
  tournamentAdmin,
  teamManager,
  publicViewer;

  String get label => switch (this) {
    AppRole.superAdmin => 'Super Admin',
    AppRole.tournamentAdmin => 'Tournament Admin / Auction Operator',
    AppRole.teamManager => 'Team Owner / Team Manager',
    AppRole.publicViewer => 'Public Viewer',
  };
}
