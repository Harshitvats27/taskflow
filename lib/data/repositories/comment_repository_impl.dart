import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/api_simulator.dart';
import '../datasources/mock_json_data_source.dart';

class CommentRepositoryImpl implements CommentRepository {
  final MockJsonDataSource _dataSource;
  final ApiSimulator _simulator;

  CommentRepositoryImpl(this._dataSource, this._simulator);

  @override
  Future<List<Comment>> getCommentsByTaskId(String taskId) {
    return _simulator.simulate(() async {
      final all = await _dataSource.getComments();
      return all.where((c) => c.taskId == taskId).toList();
    });
  }
}
