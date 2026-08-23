import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/exceptions.dart';
import '../providers/auth_notifier.dart';
import '../providers/project_details_notifier.dart';
import '../providers/project_details_state.dart';
import '../providers/project_list_notifier.dart';
import '../widgets/task_list_item.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_state_view.dart';
import '../widgets/confirmation_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'create_edit_project_screen.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(projectDetailsProvider.notifier)
        .fetchProjectDetails(widget.projectId));
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Project',
        message: 'Are you sure you want to delete this project? This cannot be undone.',
        confirmText: 'Delete',
        isDestructive: true,
        onConfirm: () async {
          try {
            await ref
                .read(projectListProvider.notifier)
                .deleteProject(widget.projectId);
            if (context.mounted) {
              context.pop(); // Go back to project list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project deleted successfully')),
              );
            }
          } on UnauthorizedException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting project: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectDetailsProvider);
    final session = ref.watch(authNotifierProvider).session;
    final isOrgAdmin = session?.role == 'org_admin';

    if (state.status == ProjectDetailsStatus.loading) {
      return const Scaffold(body: LoadingIndicator(message: 'Loading project...'));
    }

    if (state.status == ProjectDetailsStatus.error || state.project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: ErrorStateView(
          message: state.errorMessage ?? 'Failed to load project details',
          onRetry: () => ref
              .read(projectDetailsProvider.notifier)
              .fetchProjectDetails(widget.projectId),
        ),
      );
    }

    final project = state.project!;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CreateEditProjectScreen(existingProject: project),
                ),
              ).then((_) {
                // Refresh details when returning from edit
                ref.read(projectDetailsProvider.notifier).fetchProjectDetails(widget.projectId);
              });
            },
            tooltip: 'Edit Project',
          ),
          if (isOrgAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              color: AppColors.error,
              onPressed: () => _showDeleteConfirmation(context, ref),
              tooltip: 'Delete Project',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(projectDetailsProvider.notifier)
            .fetchProjectDetails(widget.projectId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingLg,
          children: [
            Text(
              project.description,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildTaskSummary(context, state),
            const Divider(height: AppSpacing.xxl),
            Text(
              'Tasks',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No tasks found in this project.')),
              )
            else
              ...state.tasks.map((task) => TaskListItem(
                    task: task,
                    onTap: () {
                      // Navigate to task details later
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSummary(BuildContext context, ProjectDetailsState state) {
    int todo = 0;
    int inProgress = 0;
    int review = 0;
    int done = 0;

    for (var task in state.tasks) {
      switch (task.status) {
        case 'todo':
          todo++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'review':
          review++;
          break;
        case 'done':
          done++;
          break;
      }
    }

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('Todo', todo, AppColors.statusTodo),
          _statCol('In Progress', inProgress, AppColors.statusInProgress),
          _statCol('Review', review, AppColors.statusReview),
          _statCol('Done', done, AppColors.statusDone),
        ],
      ),
    );
  }

  Widget _statCol(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTextStyles.h2.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}