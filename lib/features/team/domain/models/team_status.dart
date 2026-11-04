enum TeamStatus {
  active,
  inactive,
  archived;

  String get label => switch (this) {
    TeamStatus.active => 'Active',
    TeamStatus.inactive => 'Inactive',
    TeamStatus.archived => 'Archived',
  };
}
