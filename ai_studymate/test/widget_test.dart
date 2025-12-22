// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_studymate/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AIStudyMateApp());

    // Verify that our app title is displayed.
    expect(find.text('AI StudyMate'), findsWidgets);
  });
}
