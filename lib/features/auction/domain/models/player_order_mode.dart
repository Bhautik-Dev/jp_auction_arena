enum PlayerOrderMode {
  manual,
  random,
  category;

  String get label => switch (this) {
    PlayerOrderMode.manual => 'Manual order',
    PlayerOrderMode.random => 'Random order',
    PlayerOrderMode.category => 'Category-wise order',
  };
}
