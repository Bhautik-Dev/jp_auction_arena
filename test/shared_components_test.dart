import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/shared/widgets/app_button.dart';
import 'package:jp_auction_arena/shared/widgets/app_card.dart';
import 'package:jp_auction_arena/shared/widgets/app_error_widget.dart';
import 'package:jp_auction_arena/shared/widgets/app_loading_indicator.dart';
import 'package:jp_auction_arena/shared/widgets/app_text_field.dart';

void main() {
  group('Shared Components Tests', () {
    testWidgets('AppButton renders label and triggers callback on tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Submit',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);
    });

    testWidgets('AppCard renders child and triggers onTap when provided', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppTextField renders and allows text entry', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Player Name',
              hintText: 'Enter name',
            ),
          ),
        ),
      );

      expect(find.text('Player Name'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Virat Kohli');
      expect(controller.text, 'Virat Kohli');
    });

    testWidgets('AppLoadingIndicator renders spinner and message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(message: 'Loading data...'),
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppErrorWidget renders message and retry button', (
      WidgetTester tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Failed to fetch',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to fetch'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
