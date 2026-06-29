// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bkdmm/app/app_theme.dart';

void main() {
  testWidgets('App theme smoke test', (WidgetTester tester) async {
    // Build a simple widget to verify the app theme loads correctly.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          title: 'Bkdmm Test',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: Text('Bkdmm'),
            ),
          ),
        ),
      ),
    );

    // Verify that the app loads with the expected text.
    expect(find.text('Bkdmm'), findsOneWidget);
  });

  testWidgets('Color scheme test', (WidgetTester tester) async {
    // Verify that AppTheme creates valid color schemes.
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;

    expect(lightTheme, isA<ThemeData>());
    expect(darkTheme, isA<ThemeData>());
    expect(lightTheme.colorScheme, isA<ColorScheme>());
    expect(darkTheme.colorScheme, isA<ColorScheme>());
  });
}