enum CricketFormat {
  t10,
  t20,
  odi,
  test,
  custom;

  String get label => switch (this) {
    CricketFormat.t10 => 'T10',
    CricketFormat.t20 => 'T20',
    CricketFormat.odi => 'ODI',
    CricketFormat.test => 'Test',
    CricketFormat.custom => 'Custom',
  };
}
