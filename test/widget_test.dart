import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/main.dart';

void main() {
  testWidgets('Jumbo Music App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JumboMusicApp());

    // Verify app title or core elements exist
    expect(find.text('JUMBO MUSIC'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });
}
