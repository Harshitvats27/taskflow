import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/providers.dart';
import '../providers/task_details_notifier.dart';
import '../providers/task_details_state.dart';
import '../providers/task_list_notifier.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_state_view.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/status_chip.dart';
import '../widgets/priority_chip.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(taskDetailsProvider.notifier).loadTask(widget.taskId));
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Task',
        message: 'Are you sure you want to delete this task? This cannot be undone.',
        confirmText: 'Delete',
        isDestructive: true,
        onConfirm: () {
          ref.read(taskListProvider.notifier).deleteTask(widget.taskId).catchError((e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.error,
              ));
            }
          });
          if (context.canPop()) context.pop();
        },
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['todo', 'in_progress', 'review', 'done'].map((status) {
            return RadioListTile<String>(
              title: Text(status.replaceAll('_', ' ').toUpperCase()),
              value: status,
              groupValue: currentStatus,
              onChanged: (val) {
                if (val != null) {
                  Navigator.pop(ctx);
                    ref.read(taskDetailsProvider.notifier).updateStatus(val).catchError((e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ));
                      }
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAssigneeDialog(BuildContext context, String? currentAssigneeId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final membersAsync = ref.watch(orgMembersProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(title: Text('Select Assignee', style: TextStyle(fontWeight: FontWeight.bold))),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_off)),
                  title: const Text('Unassigned'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(taskDetailsProvider.notifier).assignUser(null).catchError((e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    });
                  },
                ),
                membersAsync.when(
                  data: (members) => Column(
                    children: members.map((member) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                          child: member.avatarUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(member.name),
                        trailing: member.id == currentAssigneeId ? const Icon(Icons.check, color: Colors.blue) : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(taskDetailsProvider.notifier).assignUser(member.id).catchError((e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ));
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (state.task != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/tasks/${widget.taskId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context),
            ),
          ]
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(TaskDetailsState state) {
    if (state.status == TaskDetailsStatus.loading || state.status == TaskDetailsStatus.initial) {
      return const LoadingIndicator(message: 'Loading task...');
    } else if (state.status == TaskDetailsStatus.error) {
      return ErrorStateView(
        message: state.errorMessage ?? 'Failed to load task details',
        onRetry: () => ref.read(taskDetailsProvider.notifier).loadTask(widget.taskId),
      );
    }

    final task = state.task!;
    return RefreshIndicator(
      onRefresh: () => ref.read(taskDetailsProvider.notifier).loadTask(widget.taskId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(task.description, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                InkWell(
                  onTap: () => _showStatusDialog(context, task.status),
                  borderRadius: BorderRadius.circular(16),
                  child: StatusChip(status: task.status),
                ),
                InkWell(
                  onTap: () {}, // Priority dialog could be similar
                  borderRadius: BorderRadius.circular(16),
                  child: PriorityChip(priority: task.priority),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Due: ${DateFormat.yMd().format(task.dueDate)}',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: state.assignee?.avatarUrl != null ? NetworkImage(state.assignee!.avatarUrl!) : null,
                child: state.assignee?.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              title: const Text('Assignee'),
              subtitle: Text(state.assignee?.name ?? 'Unassigned'),
              trailing: TextButton(
                onPressed: () => _showAssigneeDialog(context, state.task?.assigneeId),
                child: Text(state.assignee == null ? 'Assign' : 'Change'),
              ),
            ),
            const Divider(height: AppSpacing.xxl),
            Text('Comments (${state.comments.length})', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            ...state.comments.map((comment) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  color: AppColors.surface,
                  child: ListTile(
                    title: Text(comment.authorId), // Should resolve author name as well realistically
                    subtitle: Text(comment.body),
                    trailing: Text(DateFormat.yMd().format(comment.createdAt)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}