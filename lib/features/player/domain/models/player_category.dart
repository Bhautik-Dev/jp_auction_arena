enum PlayerCategory {
  batsman,
  bowler,
  allRounder,
  wicketKeeper;

  String get label => switch (this) {
    PlayerCategory.batsman => 'Batsman',
    PlayerCategory.bowler => 'Bowler',
    PlayerCategory.allRounder => 'All-rounder',
    PlayerCategory.wicketKeeper => 'Wicket-keeper',
  };
}
