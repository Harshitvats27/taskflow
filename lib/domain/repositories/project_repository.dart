import '../entities/project.dart';
import '../entities/requests.dart';
import '../entities/responses.dart';

abstract class ProjectRepository {
  /// Returns all projects belonging to [orgId].
  Future<List<Project>> getProjectsByOrgId(String orgId);

  /// Returns the project with [id], throws [NotFoundException] if absent.
  Future<ProjectResponse> getProjectById(String id);

  /// Creates a new project from [request] and returns the persisted entity.
  Future<ProjectResponse> createProject(CreateProjectRequest request);

  /// Applies non-null fields in [request] to the stored project.
  Future<ProjectResponse> updateProject(UpdateProjectRequest request);

  /// Permanently removes the project with [id] from the in-memory store.
  /// Throws [NotFoundException] if [id] is unknown.
  Future<void> deleteProject(String id);
}