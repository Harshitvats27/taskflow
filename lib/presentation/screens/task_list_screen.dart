import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/requests.dart';
import '../providers/task_list_notifier.dart';
import '../providers/task_list_state.dart';
import '../widgets/task_list_item.dart';
import '../widgets/offline_banner.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../../core/di/providers.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const TaskListScreen({super.key, this.projectId});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskListProvider.notifier).fetchTasks(
            initialFilter: TaskFilter(projectId: widget.projectId),
          );
    });
  }

  void _showFilterDialog(BuildContext context, TaskFilter currentFilter) {
    showDialog(
      context: context,
      builder: (ctx) {
        String? status = currentFilter.status;
        String? priority = currentFilter.priority;
        return AlertDialog(
          title: const Text('Filter Tasks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'todo', child: Text('Todo')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'review', child: Text('Review')),
                  DropdownMenuItem(value: 'done', child: Text('Done')),
                ],
                onChanged: (val) => status = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                ],
                onChanged: (val) => priority = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(taskListProvider.notifier).updateFilter(
                      TaskFilter(
                        projectId: widget.projectId,
                        status: status,
                        priority: priority,
                      ),
                    );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectId != null ? 'Project Tasks' : 'My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, state.filter),
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (ref.read(isOfflineProvider)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot create tasks while offline.')),
            );
            return;
          }
          context.push('/task/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(TaskListState state) {
    if (state.status == TaskListStatus.initial || state.status == TaskListStatus.loading) {
      return const LoadingIndicator(message: 'Loading tasks...');
    }

    final offlineBanner = OfflineBanner(
      cacheKey: 'cached_all_tasks',
      onRetry: () => ref.read(taskListProvider.notifier).fetchTasks(),
    );

    if (state.status == TaskListStatus.error) {
      return Column(
        children: [
          offlineBanner,
          Expanded(
            child: ErrorStateView(
              message: state.errorMessage ?? 'Failed to load tasks',
              onRetry: () => ref.read(taskListProvider.notifier).fetchTasks(),
            ),
          ),
        ],
      );
    } else if (state.status == TaskListStatus.empty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(taskListProvider.notifier).fetchTasks(),
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
                    icon: Icons.assignment_outlined,
                    title: 'No tasks found',
                    message: 'There are no tasks matching your current filters.',
                    buttonText: 'Create Task',
                    onAction: () {
                      if (ref.read(isOfflineProvider)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cannot create tasks while offline.')),
                        );
                        return;
                      }
                      context.push('/task/create');
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
            onRefresh: () => ref.read(taskListProvider.notifier).fetchTasks(),
            child: ListView.builder(
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                return TaskListItem(
                  task: task,
                  onTap: () => context.push('/tasks/${task.id}'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}