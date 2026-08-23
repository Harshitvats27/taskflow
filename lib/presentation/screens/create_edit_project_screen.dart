import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/project.dart';
import '../providers/project_list_notifier.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/loading_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class CreateEditProjectScreen extends ConsumerStatefulWidget {
  final Project? existingProject;

  const CreateEditProjectScreen({super.key, this.existingProject});

  @override
  ConsumerState<CreateEditProjectScreen> createState() =>
      _CreateEditProjectScreenState();
}

class _CreateEditProjectScreenState
    extends ConsumerState<CreateEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingProject?.name);
    _descriptionController =
        TextEditingController(text: widget.existingProject?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.existingProject == null) {
        // Create
        await ref
            .read(projectListProvider.notifier)
            .createProject(_nameController.text, _descriptionController.text);
      } else {
        // Update
        await ref.read(projectListProvider.notifier).updateProject(
              widget.existingProject!.id,
              _nameController.text,
              _descriptionController.text,
            );
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : 'New Project'),
      ),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _nameController,
                label: 'Project Name',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_isLoading)
                const LoadingIndicator(message: 'Saving...')
              else
                PrimaryButton(
                  text: isEditing ? 'Save Changes' : 'Create Project',
                  onPressed: _submit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
