abstract final class RouteNames {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const unauthorized = '/unauthorized';
  static const dashboard = '/app/dashboard';
  static const auctions = '/app/auctions';
  static const auctionCreate = '/app/auctions/create';
  static const auctionDetail = '/app/auctions/:auctionId';
  static const auctionEdit = '/app/auctions/:auctionId/edit';
  static const auctionSettings = '/app/auctions/:auctionId/settings';
  static const tournaments = '/app/tournaments';
  static const tournamentCreate = '/app/tournaments/create';
  static const tournamentDetail = '/app/tournaments/:tournamentId';
  static const tournamentEdit = '/app/tournaments/:tournamentId/edit';
  static const teams = '/app/teams';
  static const players = '/app/players';
  static const auctionSetup = '/app/auction/setup';
  static const liveAuction = '/app/auction/live';
  static const results = '/app/results';
  static const reports = '/app/reports';
  static const history = '/app/history';
  static const settings = '/app/settings';
  static const teamPortal = '/app/team';
  static const publicLive = '/live/:eventId';

  static String tournamentDetailPath(String id) =>
      '/app/tournaments/${Uri.encodeComponent(id)}';
  static String tournamentEditPath(String id) =>
      '${tournamentDetailPath(id)}/edit';
  static String auctionDetailPath(String id) =>
      '/app/auctions/${Uri.encodeComponent(id)}';
  static String auctionEditPath(String id) => '${auctionDetailPath(id)}/edit';
  static String auctionSettingsPath(String id) =>
      '${auctionDetailPath(id)}/settings';
}
