class AuthMockModel {
  final List<TestCredential> testCredentials;
  final MockLoginResponse mockLoginResponse;

  const AuthMockModel({
    required this.testCredentials,
    required this.mockLoginResponse,
  });

  factory AuthMockModel.fromJson(Map<String, dynamic> json) {
    return AuthMockModel(
      testCredentials: (json['test_credentials'] as List)
          .map((e) => TestCredential.fromJson(e))
          .toList(),
      mockLoginResponse: MockLoginResponse.fromJson(json['mock_login_response']),
    );
  }
}

class TestCredential {
  final String email;
  final String password;
  final String orgId;
  final String role;

  const TestCredential({
    required this.email,
    required this.password,
    required this.orgId,
    required this.role,
  });

  factory TestCredential.fromJson(Map<String, dynamic> json) {
    return TestCredential(
      email: json['email'],
      password: json['password'],
      orgId: json['org_id'],
      role: json['role'],
    );
  }
}

class MockLoginResponse {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;

  const MockLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory MockLoginResponse.fromJson(Map<String, dynamic> json) {
    return MockLoginResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      accessTokenExpiresInSeconds: json['access_token_expires_in_seconds'],
      refreshTokenExpiresInSeconds: json['refresh_token_expires_in_seconds'],
    );
  }
}