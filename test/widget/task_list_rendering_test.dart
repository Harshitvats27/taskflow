import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/presentation/screens/task_list_screen.dart';
import 'package:taskflow/presentation/providers/task_list_notifier.dart';
import 'package:taskflow/presentation/providers/task_list_state.dart';
import 'package:taskflow/domain/entities/task.dart';
import 'package:taskflow/domain/entities/requests.dart';
import 'package:taskflow/presentation/widgets/task_list_item.dart';

class MockTaskListNotifier extends Notifier<TaskListState> implements TaskListNotifier {
  final TaskListState _initialState;
  MockTaskListNotifier(this._initialState);

  @override
  TaskListState build() => _initialState;

  @override
  Future<void> fetchTasks({TaskFilter? initialFilter}) async {}
  
  @override
  Future<void> updateFilter(TaskFilter newFilter) async {}

  @override
  Future<void> quickUpdateStatus(String taskId, String newStatus) async {}
  
  @override
  Future<void> quickUpdatePriority(String taskId, String newPriority) async {}
  
  @override
  Future<void> deleteTask(String taskId) async {}
}

void main() {
  Widget createWidgetUnderTest(TaskListState initialState) {
    return ProviderScope(
      overrides: [
        taskListProvider.overrideWith(() => MockTaskListNotifier(initialState)),
      ],
      child: const MaterialApp(
        home: TaskListScreen(projectId: 'p1'),
      ),
    );
  }

  testWidgets('Renders loading state', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(const TaskListState(status: TaskListStatus.loading)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Renders empty state', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(const TaskListState(status: TaskListStatus.empty)));
    expect(find.text('No tasks found'), findsOneWidget);
  });

  testWidgets('Renders error state', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(const TaskListState(status: TaskListStatus.error, errorMessage: 'Failed to load')));
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Renders success state with tasks', (tester) async {
    final tTasks = <AppTask>[
      AppTask(
        id: 't1',
        projectId: 'p1',
        title: 'Mock Task 1',
        description: 'Mock Description',
        status: 'todo',
        priority: 'high',
        assigneeId: null,
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
    await tester.pumpWidget(createWidgetUnderTest(TaskListState(status: TaskListStatus.success, tasks: tTasks)));
    
    // We expect one TaskListItem widget
    expect(find.byType(TaskListItem), findsOneWidget);
    expect(find.text('Mock Task 1'), findsOneWidget);
  });
}
