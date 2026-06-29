import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_management/app.dart';

void main() {
  testWidgets('Smart Task login screen render smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Trigger router microtasks to process initial route /login
    await tester.pumpAndSettle();

    // Verify that the login screen title 'Welcome Back' is rendered.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to manage your tasks'), findsOneWidget);
  });
}
