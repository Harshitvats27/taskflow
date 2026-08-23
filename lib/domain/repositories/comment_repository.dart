import '../entities/comment.dart';

abstract class CommentRepository {
  /// Fetches all comments associated with a specific task
  Future<List<Comment>> getCommentsByTaskId(String taskId);
}
