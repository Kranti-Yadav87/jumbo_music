import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jumbo_music/services/theme_service.dart';

void main() {
  testWidgets('Jumbo Music App theme and base widget mount successfully', (
    WidgetTester tester,
  ) async {
    final themeManager = AppThemeManager.instance;

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: themeManager,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Jumbo Music',
            theme: AppThemeManager.lightTheme,
            darkTheme: AppThemeManager.darkTheme,
            themeMode: themeManager.themeMode,
            home: const Scaffold(
              body: Center(child: Text('Jumbo Music Ready')),
            ),
          );
        },
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Jumbo Music Ready'), findsOneWidget);
  });
}
