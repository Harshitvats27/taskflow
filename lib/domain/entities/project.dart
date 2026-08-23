import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String orgId;
  final String name;
  final String description;
  final int taskCount;
  final String status;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.orgId,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, orgId, name, description, taskCount, status, createdAt];
}