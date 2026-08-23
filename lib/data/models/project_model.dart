import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.orgId,
    required super.name,
    required super.description,
    required super.taskCount,
    required super.status,
    required super.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      orgId: json['org_id'],
      name: json['name'],
      description: json['description'],
      taskCount: json['task_count'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'name': name,
      'description': description,
      'task_count': taskCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}