import '../entities/session.dart';

abstract class AuthRepository {
  /// Validates [email] + [password] against mock credentials.
  /// Throws [UnauthorizedException] on mismatch.
  Future<Session> login(String email, String password);

  /// Issues a new access token using [refreshToken] without re-prompting the
  /// user. Throws [UnauthorizedException] if the refresh token is invalid.
  Future<Session> refreshSession(String refreshToken);

  /// Clears all auth data from secure storage.
  Future<void> logout();

  /// Returns the persisted [Session] or `null` if none exists.
  /// Does NOT check expiry — callers decide whether to refresh.
  Future<Session?> getCurrentSession();
}