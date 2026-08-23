import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/requests.dart';
import '../../domain/entities/responses.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/api_simulator.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/mock_json_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final MockJsonDataSource _dataSource;
  final ApiSimulator _simulator;
  final LocalStorageService _localStorage;
  final bool Function() _getIsOffline;
  final _uuid = const Uuid();

  TaskRepositoryImpl(
    this._dataSource,
    this._simulator,
    this._localStorage,
    this._getIsOffline,
  );

  // -----------------------------------------------------------------
  // Reads
  // -----------------------------------------------------------------

  @override
  Future<List<AppTask>> getTasks({
    TaskFilter? filter,
  }) {
    return _simulator.simulate(() async {
      final cacheKey = 'cached_all_tasks';
      List<AppTask> all;

      if (_getIsOffline()) {
        final cached = _localStorage.getString(cacheKey);
        if (cached != null) {
          final List decoded = jsonDecode(cached);
          all = decoded.map((e) => TaskModel.fromJson(e)).toList();
        } else {
          all = [];
        }
      } else {
        all = await _dataSource.getTasks();
        final encoded = jsonEncode(all.map((e) => (e as TaskModel).toJson()).toList());
        await _localStorage.saveString(cacheKey, encoded);
      }

      var results = all.toList();

      if (filter != null && !filter.isEmpty) {
        if (filter.projectId != null) {
          results = results.where((t) => t.projectId == filter.projectId).toList();
        }
        if (filter.orgId != null) {
          final projects = await _dataSource.getProjects();
          final orgProjectIds = projects
              .where((p) => p.orgId == filter.orgId)
              .map((p) => p.id)
              .toSet();
          results = results.where((t) => orgProjectIds.contains(t.projectId)).toList();
        }
        if (filter.status != null) {
          results = results.where((t) => t.status == filter.status).toList();
        }
        if (filter.priority != null) {
          results = results.where((t) => t.priority == filter.priority).toList();
        }
        if (filter.assigneeId != null) {
          results = results.where((t) => t.assigneeId == filter.assigneeId).toList();
        }
        if (filter.dueBefore != null) {
          results = results.where((t) => t.dueDate.isBefore(filter.dueBefore!)).toList();
        }
        if (filter.dueAfter != null) {
          results = results.where((t) => t.dueDate.isAfter(filter.dueAfter!)).toList();
        }
      }

      return results;
    });
  }

  @override
  Future<TaskResponse> getTaskById(String id) {
    return _simulator.simulate(() async {
      _simulator.checkForceNotFound(id, label: 'Task');

      List<AppTask> all;
      if (_getIsOffline()) {
        final cached = _localStorage.getString('cached_all_tasks');
        if (cached != null) {
          final List decoded = jsonDecode(cached);
          all = decoded.map((e) => TaskModel.fromJson(e)).toList();
        } else {
          all = [];
        }
      } else {
        all = await _dataSource.getTasks();
      }

      final match = all.where((t) => t.id == id).toList();
      if (match.isEmpty) throw NotFoundException('Task "$id" not found');
      return TaskResponse(task: match.first);
    });
  }

  // -----------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------

  @override
  Future<TaskResponse> createTask(CreateTaskRequest request) {
    return _simulator.simulate(() async {
      if (_getIsOffline()) throw OfflineException();

      // Validate required fields — throws ValidationException if empty
      _simulator.validateRequired({
        'projectId': request.projectId,
        'title': request.title,
        'status': request.status,
        'priority': request.priority,
      });

      final now = DateTime.now().toUtc();
      final newTask = TaskModel(
        id: _uuid.v4(),
        projectId: request.projectId,
        title: request.title.trim(),
        description: request.description.trim(),
        status: request.status,
        priority: request.priority,
        assigneeId: request.assigneeId,
        dueDate: request.dueDate,
        createdAt: now,
      );

      await _dataSource.addTask(newTask);
      return TaskResponse(task: newTask);
    });
  }

  @override
  Future<TaskResponse> updateTask(UpdateTaskRequest request) {
    return _simulator.simulate(() async {
      if (_getIsOffline()) throw OfflineException();

      _simulator.checkForceNotFound(request.id, label: 'Task');

      final all = await _dataSource.getTasks();
      final existing = all.where((t) => t.id == request.id).toList();
      if (existing.isEmpty) throw NotFoundException('Task "${request.id}" not found');

      final old = existing.first;

      // Resolve new title and validate
      final newTitle = request.title?.trim() ?? old.title;
      if (newTitle.isEmpty) {
        throw ValidationException('Field "title" must not be empty');
      }

      // Resolve assignee — clearAssignee wins over a new assigneeId
      String? resolvedAssignee;
      if (request.clearAssignee) {
        resolvedAssignee = null;
      } else {
        resolvedAssignee = request.assigneeId ?? old.assigneeId;
      }

      final updated = TaskModel(
        id: old.id,
        projectId: old.projectId,
        title: newTitle,
        description: request.description?.trim() ?? old.description,
        status: request.status ?? old.status,
        priority: request.priority ?? old.priority,
        assigneeId: resolvedAssignee,
        dueDate: request.dueDate ?? old.dueDate,
        createdAt: old.createdAt,
      );

      await _dataSource.updateTask(updated);
      return TaskResponse(task: updated);
    });
  }

  @override
  Future<void> deleteTask(String id) {
    return _simulator.simulate(() async {
      if (_getIsOffline()) throw OfflineException();

      _simulator.checkForceNotFound(id, label: 'Task');
      final all = await _dataSource.getTasks();
      if (all.every((t) => t.id != id)) {
        throw NotFoundException('Task "$id" not found');
      }
      await _dataSource.deleteTask(id);
    });
  }
}
