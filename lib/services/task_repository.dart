import 'package:uuid/uuid.dart';
import '../core/supabase_config.dart';
import '../models/task_model.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Local-first data layer for tasks.
///
/// Design: every write lands in the Hive box first (so the UI is instant
/// and works fully offline / in guest mode). If a user is signed in, the
/// same write is mirrored to Supabase in the background. This keeps one
/// code path for both guest and authenticated users — screens never need
/// to branch on auth state.
class TaskRepository {
  final _uuid = const Uuid();

  bool get _isLoggedIn => SupabaseConfig.isLoggedIn;
  String? get _userId => SupabaseConfig.currentUser?.id;

  List<TaskModel> getAll() =>
      LocalStorageService.taskBox.values.toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));

  Future<TaskModel> create({
    required String title,
    String? description,
    required String category,
    required String priority,
    required DateTime deadline,
    DateTime? suggestedStart,
    int estimatedMinutes = 60,
    String? courseCode,
  }) async {
    final task = TaskModel(
      id: _uuid.v4(),
      userId: _userId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      deadline: deadline,
      suggestedStart: suggestedStart,
      estimatedMinutes: estimatedMinutes,
      courseCode: courseCode,
      isSynced: false,
    );

    await LocalStorageService.taskBox.put(task.id, task);
    await NotificationService.instance.scheduleTaskReminder(task);

    if (_isLoggedIn) {
      await _pushToSupabase(task);
    }
    return task;
  }

  Future<TaskModel> update(TaskModel task) async {
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    await task.save();
    await NotificationService.instance.scheduleTaskReminder(task);

    if (_isLoggedIn) {
      await _pushToSupabase(task);
    }
    return task;
  }

  Future<void> toggleComplete(TaskModel task) async {
    final nowCompleted = task.status != 'completed';
    task.status = nowCompleted ? 'completed' : 'pending';
    task.completedAt = nowCompleted ? DateTime.now() : null;
    await update(task);
  }

  Future<void> delete(TaskModel task) async {
    await NotificationService.instance.cancelTaskReminder(task.id);
    if (_isLoggedIn) {
      try {
        await SupabaseConfig.client.from('tasks').delete().eq('id', task.id);
      } catch (_) {
        // Offline or RLS hiccup — local delete still proceeds; a future
        // sync pass can reconcile stragglers if we track tombstones.
      }
    }
    await task.delete();
  }

  Future<void> _pushToSupabase(TaskModel task) async {
    if (_userId == null) return;
    try {
      await SupabaseConfig.client
          .from('tasks')
          .upsert(task.toSupabaseMap(userId: _userId!));
      task.isSynced = true;
      await task.save();
    } catch (_) {
      // Leave isSynced = false; SyncService retries on next app resume.
    }
  }

  /// Pulls the signed-in user's tasks from Supabase and merges them into
  /// the local Hive box (remote wins on conflict, keyed by id).
  Future<void> pullFromSupabase() async {
    if (!_isLoggedIn || _userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('tasks')
          .select()
          .eq('user_id', _userId!);
      for (final row in rows as List) {
        final remote = TaskModel.fromSupabaseMap(row as Map<String, dynamic>);
        await LocalStorageService.taskBox.put(remote.id, remote);
        await NotificationService.instance.scheduleTaskReminder(remote);
      }
    } catch (_) {
      // No connection — the local cache (or guest data) remains the
      // source of truth until the next successful pull.
    }
  }

  /// Uploads every locally-created, unsynced task after a guest signs up
  /// or logs in, so nothing they entered before authenticating is lost.
  Future<void> migrateGuestDataToAccount(String userId) async {
    final unsynced = LocalStorageService.taskBox.values
        .where((t) => t.userId == null || !t.isSynced)
        .toList();
    for (final task in unsynced) {
      task.userId = userId;
      await SupabaseConfig.client
          .from('tasks')
          .upsert(task.toSupabaseMap(userId: userId));
      task.isSynced = true;
      await task.save();
    }
  }
}
