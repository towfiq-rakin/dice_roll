import 'package:dice_roll/game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder roll(int player) => find.byKey(ValueKey('roll-$player'));
Finder score(int player, int points) => find.descendant(
  of: find.byKey(ValueKey('score-$player')),
  matching: find.text('$points / 30'),
);

Future<void> finishRoll(WidgetTester tester, int player) async {
  await tester.ensureVisible(roll(player));
  await tester.tap(roll(player));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Turns alternate and animation blocks duplicate rolls', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          onLogout: () {},
          rollDice: () {
            calls++;
            return 4;
          },
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Player 2')).dy,
      lessThan(tester.getTopLeft(find.text('Player 1')).dy),
    );
    expect(tester.widget<FilledButton>(roll(1)).onPressed, isNull);
    await tester.tap(roll(0));
    await tester.pump();
    expect(tester.widget<FilledButton>(roll(0)).onPressed, isNull);
    expect(tester.widget<FilledButton>(roll(1)).onPressed, isNull);
    expect(score(0, 0), findsOneWidget);
    await tester.tap(roll(0));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(score(0, 4), findsOneWidget);
    expect(score(1, 0), findsOneWidget);
    expect(tester.widget<FilledButton>(roll(0)).onPressed, isNull);
    await finishRoll(tester, 1);
    expect(score(1, 4), findsOneWidget);
    expect(tester.widget<FilledButton>(roll(0)).onPressed, isNotNull);
  });

  testWidgets('Player 1 wins at 30 and replay resets scores, dice and turn', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(onLogout: () {}, rollDice: () => 6),
      ),
    );
    for (var turn = 0; turn < 9; turn++) {
      await finishRoll(tester, turn % 2);
    }
    expect(find.text('Player 1 wins!'), findsOneWidget);
    expect(score(0, 30), findsOneWidget);
    expect(score(1, 24), findsOneWidget);
    expect(find.text('Roll again'), findsNWidgets(2));
    await tester.tap(roll(1));
    await tester.pumpAndSettle();
    expect(score(0, 0), findsOneWidget);
    expect(score(1, 0), findsOneWidget);
    expect(find.text('First to 30 wins'), findsOneWidget);
    expect(tester.widget<FilledButton>(roll(0)).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(roll(1)).onPressed, isNull);
    expect(
      tester
          .widgetList<DiceFace>(find.byType(DiceFace))
          .every((dice) => dice.value == 1),
      isTrue,
    );
  });

  testWidgets('Player 2 wins when a roll crosses 30', (tester) async {
    final results = [1, 6, 1, 6, 1, 6, 1, 6, 1, 5, 1, 2].iterator;
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(
          onLogout: () {},
          rollDice: () {
            results.moveNext();
            return results.current;
          },
        ),
      ),
    );
    for (var turn = 0; turn < 12; turn++) {
      await finishRoll(tester, turn % 2);
    }
    expect(find.text('Player 2 wins!'), findsOneWidget);
    expect(score(1, 31), findsOneWidget);
  });

  testWidgets('Small portrait and landscape layouts remain usable', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: GamePage(key: UniqueKey(), onLogout: () {}, rollDice: () => 1),
        ),
      );
      await finishRoll(tester, 0);
      await finishRoll(tester, 1);
      expect(score(0, 1), findsOneWidget);
      expect(score(1, 1), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Leaving during a roll safely cancels the animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GamePage(onLogout: () {}, rollDice: () => 3),
      ),
    );
    await tester.tap(roll(0));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
