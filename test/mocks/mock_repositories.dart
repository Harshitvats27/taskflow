import 'package:mocktail/mocktail.dart';
import 'package:taskflow/domain/repositories/auth_repository.dart';
import 'package:taskflow/domain/repositories/comment_repository.dart';
import 'package:taskflow/domain/repositories/notification_repository.dart';
import 'package:taskflow/domain/repositories/project_repository.dart';
import 'package:taskflow/domain/repositories/task_repository.dart';
import 'package:taskflow/domain/repositories/user_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockCommentRepository extends Mock implements CommentRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}
class MockProjectRepository extends Mock implements ProjectRepository {}
class MockTaskRepository extends Mock implements TaskRepository {}
class MockUserRepository extends Mock implements UserRepository {}
