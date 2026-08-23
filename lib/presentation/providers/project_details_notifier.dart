import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/requests.dart';
import 'project_details_state.dart';

final projectDetailsProvider = NotifierProvider<ProjectDetailsNotifier, ProjectDetailsState>(
  () => ProjectDetailsNotifier(),
);

class ProjectDetailsNotifier extends Notifier<ProjectDetailsState> {
  @override
  ProjectDetailsState build() {
    return ProjectDetailsState.initial();
  }

  Future<void> fetchProjectDetails(String projectId) async {
    state = state.copyWith(status: ProjectDetailsStatus.loading);
    try {
      final projectRepo = ref.read(projectRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);

      final projectRes = await projectRepo.getProjectById(projectId);
      final tasks = await taskRepo.getTasks(filter: TaskFilter(projectId: projectId));

      state = state.copyWith(
        status: ProjectDetailsStatus.success,
        project: projectRes.project,
        tasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProjectDetailsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
