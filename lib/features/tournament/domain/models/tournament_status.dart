enum TournamentStatus {
  draft,
  active,
  completed,
  archived;

  bool get canActivate => this == TournamentStatus.draft;
  bool get canDeactivate => this == TournamentStatus.active;
  bool get canArchive => this == TournamentStatus.completed;

  String get label => switch (this) {
    TournamentStatus.draft => 'Draft',
    TournamentStatus.active => 'Active',
    TournamentStatus.completed => 'Completed',
    TournamentStatus.archived => 'Archived',
  };
}
