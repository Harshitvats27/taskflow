import 'package:equatable/equatable.dart';

class AppTask extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final DateTime dueDate;
  final DateTime createdAt;

  const AppTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    required this.dueDate,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, projectId, title, description, status, priority, assigneeId, dueDate, createdAt];
}