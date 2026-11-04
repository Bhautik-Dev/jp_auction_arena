enum TeamStatus {
  active,
  inactive;

  String get label => this == TeamStatus.active ? 'Active' : 'Inactive';
}
