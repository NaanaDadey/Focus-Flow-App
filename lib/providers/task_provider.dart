import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo;
  TaskProvider({TaskRepository? repo}) : _repo = repo ?? TaskRepository() {
    refresh();
  }

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  List<TaskModel> get pending =>
      _tasks.where((t) => t.status == 'pending' || t.status == 'in_progress').toList();

  List<TaskModel> get completed =>
      _tasks.where((t) => t.status == 'completed').toList();

  List<TaskModel> get overdue => _tasks.where((t) => t.isOverdue).toList();

  List<TaskModel> get dueToday {
    final now = DateTime.now();
    return _tasks
        .where((t) =>
            !t.isCompleted &&
            t.deadline.year == now.year &&
            t.deadline.month == now.month &&
            t.deadline.day == now.day)
        .toList();
  }

  List<TaskModel> get dueThisWeek {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return _tasks
        .where((t) =>
            !t.isCompleted && t.deadline.isAfter(now) && t.deadline.isBefore(weekEnd))
        .toList();
  }

  double get completionRate {
    if (_tasks.isEmpty) return 0;
    return completed.length / _tasks.length;
  }

  void refresh() {
    _tasks = _repo.getAll();
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String? description,
    required String category,
    required String priority,
    required DateTime deadline,
    DateTime? suggestedStart,
    int estimatedMinutes = 60,
    String? courseCode,
  }) async {
    await _repo.create(
      title: title,
      description: description,
      category: category,
      priority: priority,
      deadline: deadline,
      suggestedStart: suggestedStart,
      estimatedMinutes: estimatedMinutes,
      courseCode: courseCode,
    );
    refresh();
  }

  Future<void> updateTask(TaskModel task) async {
    await _repo.update(task);
    refresh();
  }

  Future<void> toggleComplete(TaskModel task) async {
    await _repo.toggleComplete(task);
    refresh();
  }

  Future<void> deleteTask(TaskModel task) async {
    await _repo.delete(task);
    refresh();
  }
}
