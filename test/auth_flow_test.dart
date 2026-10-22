import 'package:aimedicalreportanalyzer/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('auth screen switches between login and signup modes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AuthScreen()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsNWidgets(2));
    expect(find.text('Create account'), findsWidgets);
  });
}
