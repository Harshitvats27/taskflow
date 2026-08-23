import 'dart:math';

import '../../core/errors/exceptions.dart';

/// Wraps every repository operation to simulate realistic API behaviour:
///
/// ┌─────────────────────────────────────────────────────────────┐
/// │  Simulated Error Triggers (document these in the README)   │
/// ├──────────────────────┬──────────────────────────────────────┤
/// │ Condition            │ Exception thrown                     │
/// ├──────────────────────┼──────────────────────────────────────┤
/// │ id == "task_force_404"│ NotFoundException                   │
/// │ simulateTimeout==true │ TimeoutException (after delay)      │
/// │ simulateUnauth==true  │ UnauthorizedException               │
/// │ empty required field  │ ValidationException (at call site)  │
/// └──────────────────────┴──────────────────────────────────────┘
///
/// All flags are runtime-settable so a debug/settings screen can toggle them
/// without restarting the app.
class ApiSimulator {
  // -----------------------------------------------------------------
  // Debug flags — expose these via a Riverpod provider so a settings
  // screen can toggle them at runtime.
  // -----------------------------------------------------------------

  /// When true every [simulate] call throws [TimeoutException] after the
  /// configured delay, replicating a slow or dropped connection.
  bool simulateTimeout = false;

  /// When true every [simulate] call throws [UnauthorizedException] immediately,
  /// replicating an expired token / 401 scenario.
  bool simulateUnauth = false;

  // -----------------------------------------------------------------
  // Delay configuration
  // -----------------------------------------------------------------

  final int _minDelayMs;
  final int _maxDelayMs;
  final _rng = Random();

  ApiSimulator({
    int minDelayMs = 300,
    int maxDelayMs = 800,
  })  : _minDelayMs = minDelayMs,
        _maxDelayMs = maxDelayMs;

  // -----------------------------------------------------------------
  // Core wrapper
  // -----------------------------------------------------------------

  /// Wraps [operation] with artificial latency and global error flags.
  ///
  /// Usage inside a repository:
  /// ```dart
  /// return _simulator.simulate(() async {
  ///   final data = await _dataSource.getTasks();
  ///   return data.where((t) => t.projectId == projectId).toList();
  /// });
  /// ```
  Future<T> simulate<T>(Future<T> Function() operation) async {
    final delayMs =
        _minDelayMs + _rng.nextInt(_maxDelayMs - _minDelayMs + 1);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    // Global override flags — checked after delay so the UI sees realistic
    // loading state before the error surfaces.
    if (simulateUnauth) {
      throw UnauthorizedException('Simulated 401 – token expired');
    }
    if (simulateTimeout) {
      throw TimeoutException(
        'Simulated timeout after ${delayMs}ms (simulateTimeout flag is ON)',
      );
    }

    return operation();
  }

  // -----------------------------------------------------------------
  // Per-call helpers used by repositories
  // -----------------------------------------------------------------

  /// Call inside [simulate] after resolving an entity ID to check the force-404
  /// trigger.
  ///
  /// Example:
  /// ```dart
  /// simulator.checkForceNotFound(id, label: 'Task');
  /// ```
  void checkForceNotFound(String id, {String label = 'Entity'}) {
    // Trigger: any lookup whose ID ends with "_force_404" or equals "task_force_404".
    if (id == 'task_force_404' || id.endsWith('_force_404')) {
      throw NotFoundException('$label with id "$id" not found (forced 404)');
    }
  }

  /// Validates that all required string fields are non-empty.
  /// Throws [ValidationException] with a descriptive message on the first empty
  /// field found.
  ///
  /// Example:
  /// ```dart
  /// simulator.validateRequired({'title': request.title, 'projectId': request.projectId});
  /// ```
  void validateRequired(Map<String, String?> fields) {
    for (final entry in fields.entries) {
      if (entry.value == null || entry.value!.trim().isEmpty) {
        throw ValidationException('Field "${entry.key}" must not be empty');
      }
    }
  }
}