import 'dart:async';

import 'package:dice_roll/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login submits trimmed email once and handles Firebase errors', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(
          onSubmit: (email, password, isSignup) {
            calls++;
            expect(email, 'player@example.com');
            expect(password, 'password123');
            expect(isSignup, isFalse);
            return pending.future;
          },
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' player@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Please wait…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 1);
    pending.completeError(FirebaseAuthException(code: 'invalid-credential'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Signup submits as account creation', (tester) async {
    var submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(
          onSubmit: (email, password, isSignup) async {
            expect(email, 'player@example.com');
            expect(password, 'password123');
            expect(isSignup, isTrue);
            submitted = true;
          },
        ),
      ),
    );
    await tester.tap(find.text('New here? Sign up'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'player@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(submitted, isTrue);
  });

  testWidgets('Login validates required fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthPage(onSubmit: (_, _, _) async {})),
    );
    expect(find.text('Dice Roll'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('Signup validates confirmation and switches back to login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthPage(onSubmit: (_, _, _) async {})),
    );
    await tester.tap(find.text('New here? Sign up'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'player@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'different');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.ensureVisible(find.text('Already have an account? Log in'));
    await tester.tap(find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm password'), findsNothing);
    expect(find.text('Passwords do not match.'), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
  });
}
