import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/auction/presentation/screens/auction_list_screen.dart';
import 'package:jp_auction_arena/features/auth/application/auth_providers.dart';
import 'package:jp_auction_arena/features/auth/data/repositories/demo_auth_repository.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('legacy tournament URL leads to Auction Management', (
    tester,
  ) async {
    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'admin@demo.jp',
      password: 'DemoAdmin!2026',
      rememberMe: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const JpAuctionArenaApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
    router.go(RouteNames.tournaments);
    await tester.pumpAndSettle();
    expect(find.byType(AuctionListScreen), findsOneWidget);
    expect(find.text('Auctions'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
