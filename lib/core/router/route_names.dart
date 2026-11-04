/// Route path and name constants for GoRouter.
class RouteNames {
  RouteNames._();

  static const String home = 'home';
  static const String homePath = '/';

  static const String tournaments = 'tournaments';
  static const String tournamentsPath = '/tournaments';

  static const String createTournament = 'createTournament';
  static const String createTournamentPath = '/tournaments/create';

  static const String tournamentDetail = 'tournamentDetail';
  static const String tournamentDetailPath = '/tournaments/:id';

  static const String editTournament = 'editTournament';
  static const String editTournamentPath = '/tournaments/:id/edit';

  static const String teams = 'teams';
  static const String teamsPath = '/teams';

  static const String createTeam = 'createTeam';
  static const String createTeamPath = '/teams/create';

  static const String teamDetail = 'teamDetail';
  static const String teamDetailPath = '/teams/:id';

  static const String editTeam = 'editTeam';
  static const String editTeamPath = '/teams/:id/edit';

  static const String players = 'players';
  static const String playersPath = '/players';

  static const String createPlayer = 'createPlayer';
  static const String createPlayerPath = '/players/create';

  static const String playerDetail = 'playerDetail';
  static const String playerDetailPath = '/players/:id';

  static const String editPlayer = 'editPlayer';
  static const String editPlayerPath = '/players/:id/edit';
}
