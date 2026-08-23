import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/core/di/providers.dart';
import 'package:taskflow/main.dart' as app;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End App Test Full flow: Login -> Projects -> Tasks -> Create Task -> Assign', (tester) async {
      // Clear preferences and secure storage to ensure unauthenticated state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await const FlutterSecureStorage().deleteAll();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.TaskFlowApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));



      // 1. Full login flow against mock credentials
      // Verify we are on login screen
      expect(find.text('Welcome back!'), findsOneWidget);

      // Enter mock credentials (e.g., ava.admin@nimbusdigital.test)
      await tester.enterText(find.byType(TextFormField).at(0), 'ava.admin@nimbusdigital.test');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      
      // Tap login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we navigate to dashboard
      expect(find.text('You are signed in!'), findsOneWidget);
      
      // Tap to go to Projects
      await tester.tap(find.text('View Projects'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Projects'), findsOneWidget);
      // 2. Project listing loads and displays projects scoped to the logged-in org.
      // E.g., 'Website Relaunch' is in Nimbus Digital
      expect(find.text('Website Relaunch'), findsOneWidget);

      // 3. Task listing loads and displays tasks
      // Instead of going into a project, let's go to My Tasks
      // First, tap back if we were in a project, but we are still on ProjectsScreen
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('My Tasks'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // We are in Task List (My Tasks)
      expect(find.text('My Tasks'), findsWidgets);
      
      // 4. Create a task end-to-end and confirm it appears in the list
      // Tap FAB to create task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Create Task'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, 'Integration Test Task');

      // Select Project
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Website Relaunch').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Task').last); // The button text is "Create Task" (line 242: widget.taskId == null ? 'Create Task' : 'Save Changes')
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify task appears in list
      expect(find.text('Integration Test Task'), findsOneWidget);

      // 5. Assign a user to a task end-to-end and confirm the assignee updates
      // Tap the newly created task
      await tester.tap(find.text('Integration Test Task'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap the 'Assign' or 'Change' button in the ListTile
      // Ensure the screen is fully loaded first
      expect(find.text('Assignee'), findsOneWidget);
      
      // Use a more robust way to find the Assign button
      final assignButton = find.descendant(
        of: find.byType(TextButton),
        matching: find.textContaining('Assign'),
      );
      if (assignButton.evaluate().isEmpty) {
        await tester.tap(find.text('Assignee'));
      } else {
        await tester.tap(assignButton.first);
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap a member, e.g. "Marcus Lee", in the bottom sheet
      await tester.tap(find.text('Marcus Lee').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Confirm the assignee updated on the TaskDetailsScreen
      expect(find.text('Marcus Lee'), findsWidgets);
    });
}
