import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/organization_model.dart';
import '../models/user_model.dart';
import '../models/org_member_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/auth_mock_model.dart';

/// Loads `TaskFlow-MockData.json` exactly once, parses every top-level key
/// into typed model lists, and then acts as the authoritative in-memory store
/// for the duration of the app session.
///
/// All repositories go through this class for both reads AND mutations. Because
/// the lists are held in memory, any create/update/delete is immediately
/// visible to subsequent reads — exactly what you'd expect from a database.
///
/// To swap this for a real HTTP client later:
///   1. Create a `RemoteJsonDataSource` that makes HTTP calls instead of
///      reading `rootBundle`.
///   2. Move mutation methods to optimistic-update helpers.
///   3. The repositories, domain layer, and presentation layer remain untouched.
class MockJsonDataSource {
  // -----------------------------------------------------------------
  // Singleton / initialisation
  // -----------------------------------------------------------------

  static final MockJsonDataSource _instance = MockJsonDataSource._internal();
  factory MockJsonDataSource() => _instance;
  MockJsonDataSource._internal();

  bool _loaded = false;

  // -----------------------------------------------------------------
  // Mutable in-memory stores (seeded from JSON, mutated by repositories)
  // -----------------------------------------------------------------

  final List<OrganizationModel> _organizations = [];
  final List<UserModel> _users = [];
  final List<OrgMemberModel> _orgMembers = [];
  final List<ProjectModel> _projects = [];
  final List<TaskModel> _tasks = [];
  final List<CommentModel> _comments = [];
  final List<NotificationModel> _notifications = [];
  late AuthMockModel _authMock;

  // -----------------------------------------------------------------
  // Bootstrapping
  // -----------------------------------------------------------------

  /// Must be awaited before any read/write call.
  Future<void> init() async {
    if (_loaded) return;
    final jsonString = await rootBundle
        .loadString('assets/mock_data/TaskFlow-MockData.json');
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    _organizations.addAll(
      (data['organizations'] as List)
          .map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>)),
    );
    _users.addAll(
      (data['users'] as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>)),
    );
    _orgMembers.addAll(
      (data['org_members'] as List)
          .map((e) => OrgMemberModel.fromJson(e as Map<String, dynamic>)),
    );
    _projects.addAll(
      (data['projects'] as List)
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)),
    );
    _tasks.addAll(
      (data['tasks'] as List)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>)),
    );
    _comments.addAll(
      (data['comments'] as List)
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>)),
    );
    _notifications.addAll(
      (data['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)),
    );
    _authMock = AuthMockModel.fromJson(data['auth_mock'] as Map<String, dynamic>);
    _loaded = true;
  }

  // Convenience guard — every public method calls this first.
  Future<void> _ensureLoaded() async => init();

  // -----------------------------------------------------------------
  // READ helpers (return defensive copies so callers cannot mutate store)
  // -----------------------------------------------------------------

  Future<List<OrganizationModel>> getOrganizations() async {
    await _ensureLoaded();
    return List.unmodifiable(_organizations);
  }

  Future<List<UserModel>> getUsers() async {
    await _ensureLoaded();
    return List.unmodifiable(_users);
  }

  Future<List<OrgMemberModel>> getOrgMembers() async {
    await _ensureLoaded();
    return List.unmodifiable(_orgMembers);
  }

  Future<List<ProjectModel>> getProjects() async {
    await _ensureLoaded();
    return List.unmodifiable(_projects);
  }

  Future<List<TaskModel>> getTasks() async {
    await _ensureLoaded();
    return List.unmodifiable(_tasks);
  }

  Future<List<CommentModel>> getComments() async {
    await _ensureLoaded();
    return List.unmodifiable(_comments);
  }

  Future<List<NotificationModel>> getNotifications() async {
    await _ensureLoaded();
    return List.unmodifiable(_notifications);
  }

  Future<AuthMockModel> getAuthCredentials() async {
    await _ensureLoaded();
    return _authMock;
  }

  // -----------------------------------------------------------------
  // PROJECT mutations
  // -----------------------------------------------------------------

  Future<void> addProject(ProjectModel project) async {
    await _ensureLoaded();
    _projects.add(project);
  }

  Future<void> updateProject(ProjectModel updated) async {
    await _ensureLoaded();
    final idx = _projects.indexWhere((p) => p.id == updated.id);
    if (idx == -1) throw StateError('Project ${updated.id} not in store');
    _projects[idx] = updated;
  }

  Future<void> deleteProject(String id) async {
    await _ensureLoaded();
    _projects.removeWhere((p) => p.id == id);
    // Cascade delete tasks belonging to this project
    _tasks.removeWhere((t) => t.projectId == id);
  }

  // -----------------------------------------------------------------
  // TASK mutations
  // -----------------------------------------------------------------

  Future<void> addTask(TaskModel task) async {
    await _ensureLoaded();
    _tasks.add(task);
  }

  Future<void> updateTask(TaskModel updated) async {
    await _ensureLoaded();
    final idx = _tasks.indexWhere((t) => t.id == updated.id);
    if (idx == -1) throw StateError('Task ${updated.id} not in store');
    _tasks[idx] = updated;
  }

  Future<void> deleteTask(String id) async {
    await _ensureLoaded();
    _tasks.removeWhere((t) => t.id == id);
    // Cascade delete comments for this task
    _comments.removeWhere((c) => c.taskId == id);
  }

  // -----------------------------------------------------------------
  // NOTIFICATION mutations
  // -----------------------------------------------------------------

  Future<void> updateNotification(NotificationModel updated) async {
    await _ensureLoaded();
    final idx = _notifications.indexWhere((n) => n.id == updated.id);
    if (idx == -1) throw StateError('Notification ${updated.id} not in store');
    _notifications[idx] = updated;
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _ensureLoaded();
    _notifications.insert(0, notification);
  }
}
