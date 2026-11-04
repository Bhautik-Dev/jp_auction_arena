enum PlayerCategory {
  batsman,
  bowler,
  allRounder,
  wicketkeeper;

  String get label => switch (this) {
    PlayerCategory.batsman => 'Batsman',
    PlayerCategory.bowler => 'Bowler',
    PlayerCategory.allRounder => 'All-rounder',
    PlayerCategory.wicketkeeper => 'Wicketkeeper',
  };
}
