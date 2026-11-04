import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jp_auction_arena/app.dart';
import 'package:jp_auction_arena/core/constants/app_colors.dart';
import 'package:jp_auction_arena/core/routing/route_names.dart';
import 'package:jp_auction_arena/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_confirmation_dialog.dart';
import 'package:jp_auction_arena/shared/widgets/app_search_field.dart';
import 'package:jp_auction_arena/shared/widgets/app_states.dart';
import 'package:jp_auction_arena/shared/widgets/coming_soon_screen.dart';

void main() {
  testWidgets('future module routes show an explicit coming-soon screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JpAuctionArenaApp()));
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.byType(DashboardScreen)),
    ).go(RouteNames.liveAuction);
    await tester.pumpAndSettle();

    expect(find.byType(ComingSoonScreen), findsOneWidget);
    expect(find.text('Live Auction'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared controls render with the application theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.electricBlue,
            brightness: Brightness.dark,
          ),
        ),
        home: Scaffold(
          body: Column(
            children: [
              const AppPrimaryButton(label: 'Continue', onPressed: null),
              const AppSearchField(onChanged: _ignore),
              const AppEmptyState(title: 'Nothing here yet'),
              const AppLoadingIndicator(),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation dialog returns the selected result', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: AppPrimaryButton(
              label: 'Open dialog',
              onPressed: () async {
                confirmed = await AppConfirmationDialog.show(
                  context,
                  title: 'Confirm action',
                  message: 'Continue?',
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Continue?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

void _ignore(String value) {}
