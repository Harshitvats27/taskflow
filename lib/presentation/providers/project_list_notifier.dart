import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/requests.dart';
import 'auth_notifier.dart';
import 'project_list_state.dart';

final projectListProvider =
    NotifierProvider<ProjectListNotifier, ProjectListState>(
  () => ProjectListNotifier(),
);

class ProjectListNotifier extends Notifier<ProjectListState> {
  @override
  ProjectListState build() {
    // Schedule the initial fetch after the build phase is complete
    Future.microtask(() => fetchProjects());
    return ProjectListState.initial();
  }

  Future<void> fetchProjects() async {
    state = state.copyWith(status: ProjectListStatus.loading);
    try {
      final authState = ref.read(authNotifierProvider);
      final session = authState.session;
      if (session == null) {
        state = state.copyWith(
          status: ProjectListStatus.error,
          errorMessage: 'Unauthenticated',
        );
        return;
      }

      final useCase = ref.read(getProjectsUseCaseProvider);
      final projects = await useCase.execute(session.orgId);
      
      if (projects.isEmpty) {
        state = state.copyWith(
          status: ProjectListStatus.empty,
          projects: [],
        );
      } else {
        state = state.copyWith(
          status: ProjectListStatus.success,
          projects: projects,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ProjectListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> createProject(String name, String description) async {
    final authState = ref.read(authNotifierProvider);
    final session = authState.session;
    if (session == null) return;

    final useCase = ref.read(createProjectUseCaseProvider);
    final request = CreateProjectRequest(
      orgId: session.orgId,
      name: name,
      description: description,
    );
    await useCase.execute(request);
    await fetchProjects();
  }

  Future<void> updateProject(String id, String name, String description) async {
    final useCase = ref.read(updateProjectUseCaseProvider);
    final request = UpdateProjectRequest(
      id: id,
      name: name,
      description: description,
    );
    await useCase.execute(request);
    await fetchProjects();
  }

  Future<void> deleteProject(String id) async {
    final authState = ref.read(authNotifierProvider);
    final session = authState.session;
    if (session == null) return;

    final useCase = ref.read(deleteProjectUseCaseProvider);
    await useCase.execute(session, id);
    await fetchProjects();
  }
}
