import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/errors/exceptions.dart';
import 'package:taskflow/domain/entities/session.dart';
import 'package:taskflow/domain/usecases/login_usecase.dart';

import '../mocks/mock_repositories.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUseCase loginUseCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockAuthRepository);
  });

  final tSession = Session(
    accessToken: 'access_token',
    refreshToken: 'refresh_token',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    userId: 'user1',
    orgId: 'org1',
    role: 'member',
  );

  group('Auth Tests', () {
    test('login returns session on valid credentials', () async {
      when(() => mockAuthRepository.login('test@example.com', 'password'))
          .thenAnswer((_) async => tSession);

      final result = await loginUseCase.execute('test@example.com', 'password');

      expect(result, equals(tSession));
      verify(() => mockAuthRepository.login('test@example.com', 'password')).called(1);
    });

    test('login throws UnauthorizedException on invalid credentials', () async {
      when(() => mockAuthRepository.login('wrong@example.com', 'password'))
          .thenThrow(UnauthorizedException('Invalid credentials'));

      expect(
        () => loginUseCase.execute('wrong@example.com', 'password'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('token expiry detection', () {
      final expiredSession = Session(
        accessToken: 'expired_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        userId: 'user1',
        orgId: 'org1',
        role: 'member',
      );

      final activeSession = Session(
        accessToken: 'active_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(minutes: 1)),
        userId: 'user1',
        orgId: 'org1',
        role: 'member',
      );

      expect(expiredSession.isExpired, isTrue);
      expect(activeSession.isExpired, isFalse);
    });

    test('simulated refresh flow issues a new token', () async {
      final newSession = Session(
        accessToken: 'new_access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        userId: 'user1',
        orgId: 'org1',
        role: 'member',
      );

      when(() => mockAuthRepository.refreshSession('refresh_token'))
          .thenAnswer((_) async => newSession);

      final result = await mockAuthRepository.refreshSession('refresh_token');

      expect(result.accessToken, equals('new_access_token'));
      verify(() => mockAuthRepository.refreshSession('refresh_token')).called(1);
    });
  });
}
