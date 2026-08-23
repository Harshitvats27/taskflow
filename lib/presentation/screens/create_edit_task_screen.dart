import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/requests.dart';
import '../providers/auth_notifier.dart';
import '../providers/task_list_notifier.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_state_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class CreateEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;
  
  /// Pre-filled projectId if opened from a specific project
  final String? initialProjectId;

  const CreateEditTaskScreen({super.key, this.taskId, this.initialProjectId});

  @override
  ConsumerState<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _error;
  List<Project>? _projects;
  
  // Form fields
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _projectId;
  String _priority = 'medium';
  String? _assigneeId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _projectId = widget.initialProjectId;
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final session = ref.read(authNotifierProvider).session;
      if (session == null) throw Exception('Not logged in');
      
      _projects = await ref.read(projectRepositoryProvider).getProjectsByOrgId(session.orgId);
      // Removed filter by orgId since getProjectsByOrgId handles it
      
      // If editing, load the task
      if (widget.taskId != null) {
        final taskRes = await ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
        final task = taskRes.task;
        _titleController.text = task.title;
        _descriptionController.text = task.description;
        _projectId = task.projectId;
        _priority = task.priority;
        _assigneeId = task.assigneeId;
        _dueDate = task.dueDate;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    if (_projectId == null) {
      setState(() => _error = 'Please select a project');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.taskId == null) {
        // Create
        await ref.read(createTaskUseCaseProvider).execute(CreateTaskRequest(
          projectId: _projectId!,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          assigneeId: _assigneeId,
          status: 'todo',
          dueDate: _dueDate,
        ));
      } else {
        // Update
        await ref.read(updateTaskUseCaseProvider).call(UpdateTaskRequest(
          id: widget.taskId!,
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          assigneeId: _assigneeId,
          dueDate: _dueDate,
        ));
      }
      
      // Refresh task list
      ref.read(taskListProvider.notifier).fetchTasks();
      
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(orgMembersProvider);
    
    if (_isLoading && _projects == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.taskId == null ? 'Create Task' : 'Edit Task')),
        body: const LoadingIndicator(message: 'Loading form...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskId == null ? 'Create Task' : 'Edit Task'),
      ),
      body: _error != null && _projects == null
          ? ErrorStateView(message: _error!, onRetry: _loadData)
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  if (_error != null)
                    Container(
                      padding: AppSpacing.paddingSm,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  AppTextField(
                    controller: _titleController,
                    label: 'Task Title',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Title is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _projectId,
                    decoration: const InputDecoration(labelText: 'Project'),
                    items: _projects?.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: widget.taskId == null ? (val) => setState(() => _projectId = val) : null,
                    validator: (val) => val == null ? 'Please select a project' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  membersAsync.when(
                    data: (members) => DropdownButtonFormField<String?>(
                      value: _assigneeId,
                      decoration: const InputDecoration(labelText: 'Assignee'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                        ...members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
                      ],
                      onChanged: (val) => setState(() => _assigneeId = val),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Failed to load members: $e'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    title: const Text('Due Date'),
                    subtitle: Text('${_dueDate.toLocal()}'.split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_isLoading)
                    const LoadingIndicator(message: 'Saving task...')
                  else
                    PrimaryButton(
                      text: widget.taskId == null ? 'Create Task' : 'Save Changes',
                      onPressed: _submit,
                    ),
                ],
              ),
            ),
    );
  }
}