import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_storage_service.dart';

import '../../data/datasources/api_simulator.dart';
import '../../data/datasources/mock_json_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/comment_repository_impl.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/entities/user.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import '../../presentation/providers/auth_notifier.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/update_project_usecase.dart';
import '../../domain/usecases/delete_project_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/assign_user_to_task_usecase.dart';
import '../../domain/usecases/remove_assignee_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';

// ─────────────────────────────────────────────
// Infrastructure — singletons shared across layers
// ─────────────────────────────────────────────

/// The single, shared [FlutterSecureStorage] instance.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// The [SharedPreferences] instance. Must be overridden in ProviderScope.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService(ref.watch(sharedPreferencesProvider));
});

/// Offline mode toggle.
class IsOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setOffline(bool value) => state = value;
}
final isOfflineProvider = NotifierProvider<IsOfflineNotifier, bool>(() => IsOfflineNotifier());

/// Provides the last updated timestamp for a specific cache key.
final lastUpdatedProvider = Provider.family<DateTime?, String>((ref, key) {
  return ref.watch(localStorageServiceProvider).getLastUpdated(key);
});

/// The [ApiSimulator] is a singleton so all repositories share the same
/// [simulateTimeout] / [simulateUnauth] flags — toggling them from a debug
/// screen affects every inflight call immediately.
final apiSimulatorProvider = Provider<ApiSimulator>(
  (ref) => ApiSimulator(minDelayMs: 300, maxDelayMs: 800),
);

/// The [MockJsonDataSource] is a singleton so the mutable in-memory store
/// is shared; any mutation in one repository is visible to all others.
final mockJsonDataSourceProvider = Provider<MockJsonDataSource>(
  (ref) => MockJsonDataSource(),
);

// ─────────────────────────────────────────────
// Repository providers — abstract interface types
// ─────────────────────────────────────────────
// Presentation and domain layers only ever depend on these abstract providers.
// To swap in a real HTTP backend, replace the *Impl inside each provider body
// and add the new dependency. Nothing above data/ changes.

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(mockJsonDataSourceProvider),
    ref.watch(apiSimulatorProvider),
    ref.watch(secureStorageProvider),
  ),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepositoryImpl(
    ref.watch(mockJsonDataSourceProvider),
    ref.watch(apiSimulatorProvider),
    ref.watch(localStorageServiceProvider),
    () => ref.read(isOfflineProvider),
  ),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(
    ref.watch(mockJsonDataSourceProvider),
    ref.watch(apiSimulatorProvider),
    ref.watch(localStorageServiceProvider),
    () => ref.read(isOfflineProvider),
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    ref.watch(mockJsonDataSourceProvider),
    ref.watch(apiSimulatorProvider),
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.watch(mockJsonDataSourceProvider),
    ref.watch(apiSimulatorProvider),
  ),
);

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepositoryImpl(
    ref.watch(mockJsonDataSourceProvider),
    ref.watch(apiSimulatorProvider),
  ),
);

final orgMembersProvider = FutureProvider<List<User>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (!authState.isAuthenticated || authState.session == null) return [];
  
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getOrgMembers(authState.session!.orgId);
});

// ─────────────────────────────────────────────
// Use-Case providers
// ─────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final getProjectsUseCaseProvider = Provider<GetProjectsUseCase>(
  (ref) => GetProjectsUseCase(ref.watch(projectRepositoryProvider)),
);

final createProjectUseCaseProvider = Provider<CreateProjectUseCase>(
  (ref) => CreateProjectUseCase(ref.watch(projectRepositoryProvider)),
);

final updateProjectUseCaseProvider = Provider<UpdateProjectUseCase>(
  (ref) => UpdateProjectUseCase(ref.watch(projectRepositoryProvider)),
);

final deleteProjectUseCaseProvider = Provider<DeleteProjectUseCase>(
  (ref) => DeleteProjectUseCase(ref.watch(projectRepositoryProvider)),
);

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>(
  (ref) => CreateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final assignUserToTaskUseCaseProvider = Provider<AssignUserToTaskUseCase>(
  (ref) => AssignUserToTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);

final removeAssigneeUseCaseProvider = Provider<RemoveAssigneeUseCase>(
  (ref) => RemoveAssigneeUseCase(ref.watch(taskRepositoryProvider)),
);

final getTasksUseCaseProvider = Provider<GetTasksUseCase>(
  (ref) => GetTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>(
  (ref) => UpdateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>(
  (ref) => DeleteTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>(
  (ref) => GetNotificationsUseCase(ref.watch(notificationRepositoryProvider)),
);

final markNotificationReadUseCaseProvider = Provider<MarkNotificationReadUseCase>(
  (ref) => MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider)),
);

