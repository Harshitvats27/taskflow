import 'package:equatable/equatable.dart';
import '../../domain/entities/session.dart';

/// All possible auth lifecycle states.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Immutable state object carried by [AuthNotifier].
///
/// Router guards, screen builders, and widgets all read this to decide what to
/// render without ever coupling to [AuthRepository] directly.
class AuthState extends Equatable {
  final AuthStatus status;

  /// Non-null only when [status] == [AuthStatus.authenticated].
  final Session? session;

  /// Non-null only when [status] == [AuthStatus.error].
  final String? errorMessage;

  /// Set to `true` for exactly one state emission after a transparent token
  /// refresh so the UI can show a "Session refreshed" debug Snackbar.
  /// Callers should invoke [AuthNotifier.clearRefreshFlag] immediately after
  /// consuming this flag so it isn't shown again on the next rebuild.
  final bool sessionWasRefreshed;

  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.sessionWasRefreshed = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.initial;

  @override
  List<Object?> get props =>
      [status, session, errorMessage, sessionWasRefreshed];
}
