enum TournamentStatus {
  draft,
  upcoming,
  active,
  completed,
  archived,
  cancelled;

  bool get canActivate =>
      this == TournamentStatus.draft || this == TournamentStatus.upcoming;
  bool get canDeactivate => this == TournamentStatus.active;
  bool get canArchive => this == TournamentStatus.completed;

  String get label => switch (this) {
    TournamentStatus.draft => 'Draft',
    TournamentStatus.upcoming => 'Upcoming',
    TournamentStatus.active => 'Active',
    TournamentStatus.completed => 'Completed',
    TournamentStatus.archived => 'Archived',
    TournamentStatus.cancelled => 'Cancelled',
  };
}
