// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dream_visualizer/main.dart';
import 'package:dream_visualizer/services/language_service.dart';
import 'package:dream_visualizer/services/theme_service.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Create a LanguageService instance
    final languageService = LanguageService();
    final themeService = ThemeService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: languageService,
        child: DreamApp(
          languageService: languageService,
          themeService: themeService,
        ),
      ),
    );

    // Wait for the widget to build
    await tester.pumpAndSettle();

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
