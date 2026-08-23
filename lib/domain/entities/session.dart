import 'package:equatable/equatable.dart';

/// Represents an authenticated user session returned by [AuthRepository.login]
/// or [AuthRepository.refreshSession].
///
/// Stored in [FlutterSecureStorage] — never logged or printed.
class Session extends Equatable {
  final String accessToken;
  final String refreshToken;

  /// UTC timestamp when [accessToken] expires.
  final DateTime expiresAt;

  /// The ID of the authenticated user.
  final String userId;

  /// The organisation the user belongs to.
  final String orgId;

  /// The user's role within the organisation (e.g. "admin", "member").
  final String role;

  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.orgId,
    required this.role,
  });

  /// Returns `true` if the access token has already expired.
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        expiresAt,
        userId,
        orgId,
        role,
      ];
}