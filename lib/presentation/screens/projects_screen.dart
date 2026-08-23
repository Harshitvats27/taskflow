import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/project_list_notifier.dart';
import '../providers/project_list_state.dart';
import '../providers/auth_notifier.dart';
import '../widgets/offline_banner.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../../core/di/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (ref.read(isOfflineProvider)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot create projects while offline.')),
            );
            return;
          }
          context.push('/projects/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectListState state) {
    if (state.status == ProjectListStatus.loading) {
      return const LoadingIndicator(message: 'Loading projects...');
    }
    
    final orgId = ref.read(authNotifierProvider).session?.orgId ?? '';
    final offlineBanner = OfflineBanner(
      cacheKey: 'cached_projects_$orgId',
      onRetry: () => ref.read(projectListProvider.notifier).fetchProjects(),
    );

    if (state.status == ProjectListStatus.error) {
      return ErrorStateView(
        message: state.errorMessage ?? 'Failed to load projects',
        onRetry: () => ref.read(projectListProvider.notifier).fetchProjects(),
      );
    }

    if (state.status == ProjectListStatus.empty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(projectListProvider.notifier).fetchProjects(),
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
            ),
            Column(
              children: [
                offlineBanner,
                Expanded(
                  child: EmptyStateView(
                    icon: Icons.folder_open_rounded,
                    title: 'No projects yet',
                    message: 'Get started by creating your first project.',
                    buttonText: 'Create Project',
                    onAction: () {
                      if (ref.read(isOfflineProvider)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot create projects while offline.')),
                        );
                        return;
                      }
                      context.push('/projects/create');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        offlineBanner,
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(projectListProvider.notifier).fetchProjects();
            },
            child: ListView.builder(
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final project = state.projects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  elevation: 0,
                  color: AppColors.surface,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      project.name,
                      style: AppTextStyles.h3,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        project.description.isNotEmpty
                            ? project.description
                            : 'No description',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${project.taskCount} Tasks',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () => context.push('/projects/${project.id}'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}