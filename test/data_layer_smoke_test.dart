// ignore_for_file: avoid_print
// Run this from terminal: flutter test test/data_layer_smoke_test.dart
//
// Yeh test check karta hai:
//   1. MockJsonDataSource correctly parses the JSON
//   2. All repositories return expected data
//   3. ApiSimulator triggers work correctly (force_404, validation)
//
// NOTE: rootBundle works only in a real Flutter test environment,
// so yeh `flutter test` se run hoga, `dart test` se nahi.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:taskflow/data/datasources/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/errors/exceptions.dart';
import 'package:taskflow/data/datasources/mock_json_data_source.dart';
import 'package:taskflow/data/datasources/api_simulator.dart';
import 'package:taskflow/data/repositories/project_repository_impl.dart';
import 'package:taskflow/data/repositories/task_repository_impl.dart';
import 'package:taskflow/data/repositories/auth_repository_impl.dart';
import 'package:taskflow/data/repositories/user_repository_impl.dart';
import 'package:taskflow/data/repositories/notification_repository_impl.dart';
import 'package:taskflow/domain/entities/requests.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load the real asset in tests
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter/assets'),
    null,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall methodCall) async {
      return null;
    },
  );

  late MockJsonDataSource dataSource;
  late ApiSimulator simulator;

  setUp(() {
    dataSource = MockJsonDataSource();
    // Use a fast simulator (no delay) for tests
    simulator = ApiSimulator(minDelayMs: 0, maxDelayMs: 1);
  });

  group('MockJsonDataSource', () {
    test('loads organizations', () async {
      final orgs = await dataSource.getOrganizations();
      expect(orgs.length, 2);
      expect(orgs.first.name, 'Nimbus Digital');
      print('✅ Organizations: ${orgs.map((o) => o.name).toList()}');
    });

    test('loads users', () async {
      final users = await dataSource.getUsers();
      expect(users.length, 5);
      print('✅ Users: ${users.map((u) => u.name).toList()}');
    });

    test('loads projects', () async {
      final projects = await dataSource.getProjects();
      expect(projects.length, 3);
      print('✅ Projects: ${projects.map((p) => p.name).toList()}');
    });

    test('loads tasks', () async {
      final tasks = await dataSource.getTasks();
      expect(tasks.length, 15);
      print('✅ Tasks loaded: ${tasks.length}');
    });

    test('loads auth credentials', () async {
      final auth = await dataSource.getAuthCredentials();
      expect(auth.testCredentials.length, 4);
      print('✅ Auth credentials: ${auth.testCredentials.map((c) => c.email).toList()}');
    });
  });

  group('ProjectRepositoryImpl', () {
    late ProjectRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      repo = ProjectRepositoryImpl(dataSource, simulator, localStorage, () => false);
    });

    test('getProjectsByOrgId returns only org projects', () async {
      final projects = await repo.getProjectsByOrgId('org_a1b2c3');
      expect(projects.length, 2);
      expect(projects.every((p) => p.orgId == 'org_a1b2c3'), true);
      print('✅ Nimbus Digital projects: ${projects.map((p) => p.name).toList()}');
    });

    test('createProject adds to store', () async {
      final response = await repo.createProject(CreateProjectRequest(
        orgId: 'org_a1b2c3',
        name: 'Test Project',
        description: 'A test project',
      ));
      expect(response.project.name, 'Test Project');

      final all = await repo.getProjectsByOrgId('org_a1b2c3');
      expect(all.length, 3); // was 2, now 3
      print('✅ Project created: ${response.project.id}');
    });

    test('createProject throws ValidationException on empty name', () async {
      expect(
        () => repo.createProject(CreateProjectRequest(
          orgId: 'org_a1b2c3',
          name: '',
          description: 'desc',
        )),
        throwsA(isA<ValidationException>()),
      );
      print('✅ ValidationException thrown for empty name');
    });

    test('deleteProject removes project', () async {
      await repo.deleteProject('proj_1003');
      final projects = await repo.getProjectsByOrgId('org_a1b2c3');
      expect(projects.any((p) => p.id == 'proj_1003'), false);
      print('✅ Project deleted successfully');
    });
  });

  group('TaskRepositoryImpl', () {
    late TaskRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      repo = TaskRepositoryImpl(dataSource, simulator, localStorage, () => false);
    });

    test('getTasks filters by projectId', () async {
      final tasks = await repo.getTasks(filter: const TaskFilter(projectId: 'proj_1001'));
      expect(tasks.length, 6);
      print('✅ proj_1001 tasks: ${tasks.map((t) => t.title).toList()}');
    });

    test('filter by status works', () async {
      final tasks = await repo.getTasks(
        filter: const TaskFilter(projectId: 'proj_1001', status: 'todo'),
      );
      expect(tasks.every((t) => t.status == 'todo'), true);
      print('✅ Filtered todo tasks: ${tasks.length}');
    });

    test('filter by priority works', () async {
      final tasks = await repo.getTasks(
        filter: const TaskFilter(projectId: 'proj_1001', priority: 'high'),
      );
      expect(tasks.every((t) => t.priority == 'high'), true);
      print('✅ Filtered high priority tasks: ${tasks.length}');
    });

    test('getTaskById force_404 throws NotFoundException', () async {
      expect(
        () => repo.getTaskById('task_force_404'),
        throwsA(isA<NotFoundException>()),
      );
      print('✅ task_force_404 correctly throws NotFoundException');
    });

    test('createTask adds and is immediately readable', () async {
      final response = await repo.createTask(CreateTaskRequest(
        projectId: 'proj_1001',
        title: 'New test task',
        description: 'Description',
        status: 'todo',
        priority: 'medium',
        dueDate: DateTime(2026, 12, 31),
      ));
      expect(response.task.title, 'New test task');

      final fetched = await repo.getTaskById(response.task.id);
      expect(fetched.task.id, response.task.id);
      print('✅ Task created and re-fetched: ${response.task.id}');
    });

    test('updateTask status change works', () async {
      final updated = await repo.updateTask(UpdateTaskRequest(
        id: 'task_2001',
        status: 'in_progress',
      ));
      expect(updated.task.status, 'in_progress');
      print('✅ Task status updated to in_progress');
    });

    test('updateTask clearAssignee works', () async {
      final updated = await repo.updateTask(UpdateTaskRequest(
        id: 'task_2002',
        clearAssignee: true,
      ));
      expect(updated.task.assigneeId, isNull);
      print('✅ Assignee cleared successfully');
    });

    test('simulateTimeout flag throws TimeoutException', () async {
      simulator.simulateTimeout = true;
      await expectLater(
        () => repo.getTasks(filter: const TaskFilter(projectId: 'proj_1001')),
        throwsA(isA<TimeoutException>()),
      );
      simulator.simulateTimeout = false; // reset
      print('✅ simulateTimeout flag works');
    });
  });

  group('AuthRepositoryImpl', () {
    test('login succeeds with correct credentials', () async {
      // Use in-memory storage for test
      const storage = FlutterSecureStorage();
      final repo = AuthRepositoryImpl(dataSource, simulator, storage);

      final session = await repo.login(
        'ava.admin@nimbusdigital.test',
        'Password123!',
      );
      expect(session.accessToken, isNotEmpty);
      print('✅ Login successful, token: ${session.accessToken}');
    });

    test('login fails with wrong password', () async {
      const storage = FlutterSecureStorage();
      final repo = AuthRepositoryImpl(dataSource, simulator, storage);

      expect(
        () => repo.login('ava.admin@nimbusdigital.test', 'wrongpass'),
        throwsA(isA<UnauthorizedException>()),
      );
      print('✅ Wrong password throws UnauthorizedException');
    });
  });

  group('UserRepositoryImpl', () {
    late UserRepositoryImpl repo;

    setUp(() {
      repo = UserRepositoryImpl(dataSource, simulator);
    });

    test('getOrgMembers returns only org members', () async {
      final users = await repo.getOrgMembers('org_a1b2c3');
      expect(users.length, 3); // user_001, 002, 003
      print('✅ Nimbus Digital members: ${users.map((u) => u.name).toList()}');
    });
  });

  group('NotificationRepositoryImpl', () {
    late NotificationRepositoryImpl repo;

    setUp(() {
      repo = NotificationRepositoryImpl(dataSource, simulator);
    });

    test('getNotificationsForUser filters correctly', () async {
      final notifs = await repo.getNotificationsForUser('user_002');
      expect(notifs.every((n) => n.userId == 'user_002'), true);
      print('✅ Notifications for user_002: ${notifs.length}');
    });

    test('markAsRead updates read flag', () async {
      await repo.markAsRead('notif_4001');
      final notifs = await repo.getNotificationsForUser('user_002');
      final marked = notifs.firstWhere((n) => n.id == 'notif_4001');
      expect(marked.read, true);
      print('✅ Notification marked as read');
    });
  });
}
