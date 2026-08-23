import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/requests.dart';
import '../../domain/entities/responses.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/api_simulator.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/mock_json_data_source.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final MockJsonDataSource _dataSource;
  final ApiSimulator _simulator;
  final LocalStorageService _localStorage;
  final bool Function() _getIsOffline;
  final _uuid = const Uuid();

  ProjectRepositoryImpl(
    this._dataSource,
    this._simulator,
    this._localStorage,
    this._getIsOffline,
  );

  // -----------------------------------------------------------------
  // Reads
  // -----------------------------------------------------------------

  @override
  Future<List<Project>> getProjectsByOrgId(String orgId) {
    return _simulator.simulate(() async {
      final cacheKey = 'cached_projects_$orgId';
      
      if (_getIsOffline()) {
        final cached = _localStorage.getString(cacheKey);
        if (cached != null) {
          final List decoded = jsonDecode(cached);
          return decoded.map((e) => ProjectModel.fromJson(e)).toList();
        }
        return []; // No cached data
      }

      final all = await _dataSource.getProjects();
      final projects = all.where((p) => p.orgId == orgId).toList();
      
      // Save to cache
      final encoded = jsonEncode(projects.map((e) => e.toJson()).toList());
      await _localStorage.saveString(cacheKey, encoded);

      return projects;
    });
  }

  @override
  Future<ProjectResponse> getProjectById(String id) {
    return _simulator.simulate(() async {
      _simulator.checkForceNotFound(id, label: 'Project');

      List<Project> all;
      if (_getIsOffline()) {
        // Just try to find in any cached project list? 
        // We cached projects by orgId. So this might be tricky, but let's just 
        // find all cache keys for projects and look for it, or just throw OfflineException 
        // since we only cached by orgId.
        // Actually, if we are navigating from the list, we can just throw if it's not found in the list, but we don't know orgId.
        // Let's iterate all keys in SharedPreferences (LocalStorageService doesn't expose all keys currently).
        // Let's just assume we can throw OfflineException for now, or just let it fail if we can't find it.
        // Since we are offline, let's just throw OfflineException if not cached. 
        // Actually, the requirements didn't say project DETAILS must work offline perfectly if not loaded, but let's just throw OfflineException.
        throw OfflineException('Cannot fetch project details while offline');
      }

      all = await _dataSource.getProjects();
      final match = all.where((p) => p.id == id).toList();
      if (match.isEmpty) throw NotFoundException('Project "$id" not found');
      return ProjectResponse(project: match.first);
    });
  }

  // -----------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------

  @override
  Future<ProjectResponse> createProject(CreateProjectRequest request) {
    return _simulator.simulate(() async {
      if (_getIsOffline()) throw OfflineException();

      _simulator.validateRequired({
        'orgId': request.orgId,
        'name': request.name,
      });

      final now = DateTime.now().toUtc();
      final newProject = ProjectModel(
        id: _uuid.v4(),
        orgId: request.orgId,
        name: request.name.trim(),
        description: request.description.trim(),
        taskCount: 0,
        status: 'active',
        createdAt: now,
      );

      await _dataSource.addProject(newProject);
      return ProjectResponse(project: newProject);
    });
  }

  @override
  Future<ProjectResponse> updateProject(UpdateProjectRequest request) {
    return _simulator.simulate(() async {
      if (_getIsOffline()) throw OfflineException();

      _simulator.checkForceNotFound(request.id, label: 'Project');

      final all = await _dataSource.getProjects();
      final existing = all.where((p) => p.id == request.id).toList();
      if (existing.isEmpty) {
        throw NotFoundException('Project "${request.id}" not found');
      }

      final old = existing.first;
      final updatedName = request.name?.trim() ?? old.name;
      if (updatedName.isEmpty) {
        throw ValidationException('Field "name" must not be empty');
      }

      final updated = ProjectModel(
        id: old.id,
        orgId: old.orgId,
        name: updatedName,
        description: request.description?.trim() ?? old.description,
        taskCount: old.taskCount,
        status: request.status ?? old.status,
        createdAt: old.createdAt,
      );

      await _dataSource.updateProject(updated);
      return ProjectResponse(project: updated);
    });
  }

  @override
  Future<void> deleteProject(String id) {
    return _simulator.simulate(() async {
      if (_getIsOffline()) throw OfflineException();

      _simulator.checkForceNotFound(id, label: 'Project');
      final all = await _dataSource.getProjects();
      if (all.every((p) => p.id != id)) {
        throw NotFoundException('Project "$id" not found');
      }
      await _dataSource.deleteProject(id);
    });
  }
}
