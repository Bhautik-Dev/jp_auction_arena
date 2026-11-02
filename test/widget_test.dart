import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jp_auction_arena/app.dart';

void main() {
  testWidgets('JP AUCTION ARENA smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: JpAuctionArenaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('JP AUCTION ARENA'), findsWidgets);
  });
}
