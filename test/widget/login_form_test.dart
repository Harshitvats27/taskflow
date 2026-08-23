import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/presentation/screens/login_screen.dart';
import 'package:taskflow/presentation/providers/auth_notifier.dart';
import 'package:taskflow/presentation/providers/auth_state.dart';
import 'package:taskflow/domain/entities/session.dart';
import 'package:taskflow/presentation/widgets/primary_button.dart';

// Since LoginScreen uses authProvider, we can override it or mock the usecase if it's injected.
// We'll mock the AuthNotifier to control the state and actions.

class MockAuthNotifier extends Notifier<AuthState> implements AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<void> login(String email, String password) async {
    // We can simulate the login call here to verify it was called
    state = AuthState(
      status: AuthStatus.authenticated,
      session: Session(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now(),
        userId: 'u1',
        orgId: 'o1',
        role: 'member',
      ),
    );
  }

  @override
  Future<void> logout() async {}

  Future<void> register(String name, String email, String password) async {}

  @override
  Future<void> checkSession() async {}

  @override
  void clearError() {}

  @override
  void clearRefreshFlag() {}

  @override
  void recordActivity() {}

  @override
  Future<void> refreshSessionIfNeeded() async {}
}

void main() {
  testWidgets('Login form shows validation errors on empty submit', (tester) async {
    final mockAuthNotifier = MockAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => mockAuthNotifier),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Find the login button and tap it
    final loginButton = find.byType(PrimaryButton);
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Login form shows validation errors on invalid data', (tester) async {
    final mockAuthNotifier = MockAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => mockAuthNotifier),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Enter invalid email and short password
    await tester.enterText(find.byType(TextFormField).at(0), 'invalidemail');
    await tester.enterText(find.byType(TextFormField).at(1), '123');

    final loginButton = find.byType(PrimaryButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}
