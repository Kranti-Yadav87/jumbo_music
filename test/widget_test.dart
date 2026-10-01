import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/main.dart';

void main() {
  testWidgets('Jumbo Music App mounts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JumboMusicApp());

    // Verify MaterialApp mounts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
