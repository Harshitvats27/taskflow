import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/api_simulator.dart';
import '../datasources/mock_json_data_source.dart';

/// Concrete implementation that authenticates against [TaskFlow-MockData.json]
/// and stores session data in [FlutterSecureStorage].
///
/// Security rules enforced here:
///   • Plaintext password is NEVER stored — only compared in memory then discarded.
///   • Token values are NEVER passed to debugPrint / log.
///   • Credentials are NEVER hardcoded — always read via [MockJsonDataSource].
class AuthRepositoryImpl implements AuthRepository {
  final MockJsonDataSource _dataSource;
  final ApiSimulator _simulator;
  final FlutterSecureStorage _secureStorage;

  // Storage keys — scoped with 'tf_' prefix to avoid collisions
  static const _kAccessToken = 'tf_access_token';
  static const _kRefreshToken = 'tf_refresh_token';
  static const _kExpiresAt = 'tf_expires_at';
  static const _kUserId = 'tf_user_id';
  static const _kOrgId = 'tf_org_id';
  static const _kRole = 'tf_role';

  AuthRepositoryImpl(this._dataSource, this._simulator, this._secureStorage);

  // ─────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────

  @override
  Future<Session> login(String email, String password) {
    return _simulator.simulate(() async {
      _simulator.validateRequired({'email': email, 'password': password});

      final authMock = await _dataSource.getAuthCredentials();
      final matched = authMock.testCredentials
          .where((c) => c.email == email && c.password == password)
          .toList();

      // Password is compared in memory — never persisted beyond this scope
      if (matched.isEmpty) {
        throw UnauthorizedException('Invalid email or password');
      }

      final credential = matched.first;
      final response = authMock.mockLoginResponse;
      final expiresAt = DateTime.now()
          .toUtc()
          .add(Duration(seconds: response.accessTokenExpiresInSeconds));

      // Resolve userId by matching email against the users list
      final users = await _dataSource.getUsers();
      final matchedUser = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw UnauthorizedException('User profile not found'),
      );

      final session = Session(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: expiresAt,
        userId: matchedUser.id,
        orgId: credential.orgId,
        role: credential.role,
      );

      await _persistSession(session);
      return session;
    });
  }

  @override
  Future<Session> refreshSession(String refreshToken) async {
    // Simulate transparent token refresh (POST /auth/refresh in a real backend).
    // Generates a new access token; orgId + role are preserved from storage.
    final orgId = await _secureStorage.read(key: _kOrgId) ?? '';
    final role = await _secureStorage.read(key: _kRole) ?? '';
    final userId = await _secureStorage.read(key: _kUserId) ?? '';
    final storedRefresh =
        await _secureStorage.read(key: _kRefreshToken) ?? refreshToken;

    final expiresAt =
        DateTime.now().toUtc().add(const Duration(seconds: 900));

    // Token value is derived from expiry ms — not logged anywhere
    final newSession = Session(
      accessToken: 'mock.refreshed.${expiresAt.millisecondsSinceEpoch}',
      refreshToken: storedRefresh,
      expiresAt: expiresAt,
      userId: userId,
      orgId: orgId,
      role: role,
    );

    await _persistSession(newSession);
    return newSession;
  }

  @override
  Future<void> logout() async {
    // Deletes ALL stored auth keys — no trace of tokens left on device
    await _secureStorage.deleteAll();
  }

  @override
  Future<Session?> getCurrentSession() async {
    final accessToken = await _secureStorage.read(key: _kAccessToken);
    final refreshToken = await _secureStorage.read(key: _kRefreshToken);
    final expiresAtStr = await _secureStorage.read(key: _kExpiresAt);
    final userId = await _secureStorage.read(key: _kUserId);
    final orgId = await _secureStorage.read(key: _kOrgId);
    final role = await _secureStorage.read(key: _kRole);

    // Return null if any required field is missing (partial/corrupt storage)
    if (accessToken == null ||
        refreshToken == null ||
        expiresAtStr == null ||
        userId == null ||
        orgId == null ||
        role == null) {
      return null;
    }

    return Session(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAtStr),
      userId: userId,
      orgId: orgId,
      role: role,
    );
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  Future<void> _persistSession(Session session) async {
    // SECURITY: values are written to encrypted storage but NEVER logged
    await _secureStorage.write(
        key: _kAccessToken, value: session.accessToken);
    await _secureStorage.write(
        key: _kRefreshToken, value: session.refreshToken);
    await _secureStorage.write(
        key: _kExpiresAt, value: session.expiresAt.toIso8601String());
    await _secureStorage.write(key: _kUserId, value: session.userId);
    await _secureStorage.write(key: _kOrgId, value: session.orgId);
    await _secureStorage.write(key: _kRole, value: session.role);
  }
}
