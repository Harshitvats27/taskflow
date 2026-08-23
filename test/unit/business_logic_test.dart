import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/errors/exceptions.dart';
import 'package:taskflow/domain/entities/session.dart';
import 'package:taskflow/domain/entities/user.dart';
import 'package:taskflow/domain/usecases/delete_project_usecase.dart';
import 'package:taskflow/domain/usecases/assign_user_to_task_usecase.dart';

import '../mocks/mock_repositories.dart';
import 'package:taskflow/domain/entities/responses.dart';
import 'package:taskflow/domain/entities/task.dart';
import 'package:taskflow/domain/entities/requests.dart';
import 'package:taskflow/domain/entities/app_notification.dart';

class FakeUpdateTaskRequest extends Fake implements UpdateTaskRequest {}
class FakeAppNotification extends Fake implements AppNotification {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUpdateTaskRequest());
    registerFallbackValue(FakeAppNotification());
  });

  late MockProjectRepository mockProjectRepository;
  late MockAuthRepository mockAuthRepository;
  late MockTaskRepository mockTaskRepository;
  late MockUserRepository mockUserRepository;
  late MockNotificationRepository mockNotificationRepository;
  
  late DeleteProjectUseCase deleteProjectUseCase;
  late AssignUserToTaskUseCase assignUserToTaskUseCase;

  setUp(() {
    mockProjectRepository = MockProjectRepository();
    mockAuthRepository = MockAuthRepository();
    mockTaskRepository = MockTaskRepository();
    mockUserRepository = MockUserRepository();
    mockNotificationRepository = MockNotificationRepository();

    deleteProjectUseCase = DeleteProjectUseCase(mockProjectRepository);
    assignUserToTaskUseCase = AssignUserToTaskUseCase(
      mockTaskRepository,
      mockUserRepository,
      mockAuthRepository,
      mockNotificationRepository,
    );
  });

  group('DeleteProjectUseCase Authorization', () {
    test('throws UnauthorizedException if user is not org_admin', () async {
      final tSession = Session(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: 'user1',
        orgId: 'org1',
        role: 'member', // NOT org_admin
      );

      expect(
        () => deleteProjectUseCase.execute(tSession, 'project1'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('completes successfully if user is org_admin', () async {
      final tSession = Session(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: 'admin_user',
        orgId: 'org1',
        role: 'org_admin',
      );

      when(() => mockProjectRepository.deleteProject('project1')).thenAnswer((_) async {});

      await deleteProjectUseCase.execute(tSession, 'project1');
      verify(() => mockProjectRepository.deleteProject('project1')).called(1);
    });
  });

  group('AssignUserToTaskUseCase Validation', () {
    test('throws ValidationException if assigned user is not in org', () async {
      final tSession = Session(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: 'admin_user',
        orgId: 'org1',
        role: 'org_admin',
      );

      when(() => mockAuthRepository.getCurrentSession()).thenAnswer((_) async => tSession);
      when(() => mockUserRepository.getOrgMembers('org1')).thenAnswer((_) async => [
        const User(id: 'member1', name: 'Member 1', email: 'm1@example.com'),
      ]);

      // Assigning 'member2' who is not in the org members list
      expect(
        () => assignUserToTaskUseCase.execute('task1', 'member2'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('completes successfully if assigned user is in org', () async {
      final tSession = Session(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        userId: 'admin_user',
        orgId: 'org1',
        role: 'org_admin',
      );

      when(() => mockAuthRepository.getCurrentSession()).thenAnswer((_) async => tSession);
      when(() => mockUserRepository.getOrgMembers('org1')).thenAnswer((_) async => [
        const User(id: 'member1', name: 'Member 1', email: 'm1@example.com'),
      ]);
      when(() => mockTaskRepository.updateTask(any())).thenAnswer((_) async => TaskResponse(task: AppTask(
        id: 'task1', projectId: 'p1', title: 'Task 1', description: 'test', status: 'todo', priority: 'low', dueDate: DateTime.now(), createdAt: DateTime.now()
      )));
      when(() => mockNotificationRepository.addNotification(any())).thenAnswer((_) async {});

      // Assigning 'member1' who is in the org members list
      await assignUserToTaskUseCase.execute('task1', 'member1');

      verify(() => mockTaskRepository.updateTask(any())).called(1);
    });
  });
}
