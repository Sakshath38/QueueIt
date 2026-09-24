// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:branch_q/features/auth/state/auth_providers.dart';
import 'package:branch_q/main.dart';

void main() {
  testWidgets('renders the branch finder screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => 'fake-token'),
        ],
        child: const BranchQApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BranchQ Finder'), findsOneWidget);
  });
}
