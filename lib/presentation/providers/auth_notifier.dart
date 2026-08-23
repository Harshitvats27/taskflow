import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/exceptions.dart' as app_ex;
import 'auth_state.dart';

/// Riverpod [Notifier] that owns the entire auth lifecycle:
///   • Checks for a persisted session on startup.
///   • Transparently refreshes expired tokens (no user interaction).
///   • Handles login / logout.
///   • Runs a 5-minute inactivity timer that auto-logs the user out.
///
/// The router reads [authNotifierProvider] via a [ChangeNotifier] bridge and
/// re-evaluates route guards whenever this state changes — no manual
/// navigation calls from widgets are required for the happy path.
class AuthNotifier extends Notifier<AuthState> {
  Timer? _inactivityTimer;
  static const _inactivityDuration = Duration(minutes: 5);

  // ─────────────────────────────────────────────
  // Riverpod lifecycle
  // ─────────────────────────────────────────────

  @override
  AuthState build() {
    // Cancel timer if provider is ever disposed (e.g. during test teardown).
    ref.onDispose(() => _inactivityTimer?.cancel());

    // Kick off async session check without blocking the build.
    Future.microtask(checkSession);

    return const AuthState(status: AuthStatus.initial);
  }

  // ─────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────

  /// Called on app launch. Reads the stored session, refreshes it if expired.
  Future<void> checkSession() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final repo = ref.read(authRepositoryProvider);
      var session = await repo.getCurrentSession();

      if (session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      bool refreshed = false;
      if (session.isExpired) {
        session = await repo.refreshSession(session.refreshToken);
        refreshed = true;
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
        sessionWasRefreshed: refreshed,
      );
      _resetInactivityTimer();
    } catch (_) {
      // Any error during session check → treat as unauthenticated
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Authenticates with [email] + [password] via [AuthRepository].
  /// Maps repo exceptions to [AuthStatus.error] states.
  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final session = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState(status: AuthStatus.authenticated, session: session);
      _resetInactivityTimer();
    } on app_ex.UnauthorizedException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
    } on app_ex.ValidationException catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
    } on app_ex.TimeoutException {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Connection timed out. Please try again.',
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }

  /// Clears secure storage and sets state to unauthenticated.
  /// Any authenticated route will redirect to /login via the router guard.
  Future<void> logout() async {
    _inactivityTimer?.cancel();
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Always update local state even if storage fails
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Checks whether the current session is expired and refreshes transparently.
  /// Called before performing any authenticated action that requires a valid token.
  Future<void> refreshSessionIfNeeded() async {
    final s = state;
    if (s.session == null || !s.session!.isExpired) return;
    try {
      final newSession = await ref
          .read(authRepositoryProvider)
          .refreshSession(s.session!.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        session: newSession,
        sessionWasRefreshed: true,
      );
      _resetInactivityTimer();
    } catch (_) {
      await logout();
    }
  }

  /// Called by the UI after it has consumed the [AuthState.sessionWasRefreshed]
  /// flag and shown the refresh Snackbar — prevents repeated display.
  void clearRefreshFlag() {
    final s = state;
    if (s.isAuthenticated && s.sessionWasRefreshed) {
      state = AuthState(status: AuthStatus.authenticated, session: s.session);
    }
  }

  /// Clears a stale error so the login form returns to the idle state.
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Reset the inactivity timer on any user interaction.
  /// Wired to a root [Listener] widget in [main.dart].
  void recordActivity() {
    if (state.isAuthenticated) _resetInactivityTimer();
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () async {
      // Auto-logout fires on background isolate — logout() is safe to call
      await logout();
    });
  }
}

/// The single global auth state provider.
/// Import this from any screen or router that needs auth state.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
