import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow/main.dart';

void main() {
  testWidgets('TaskFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TaskFlowApp()));
    // Splash screen renders — app should not throw on startup
    await tester.pump(Duration.zero);
  });
}
