import 'package:uuid/uuid.dart';
import '../core/supabase_config.dart';
import '../models/exam_model.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Local-first data layer for exams. See [TaskRepository] for the general
/// local-first + sync pattern this mirrors.
class ExamRepository {
  final _uuid = const Uuid();

  bool get _isLoggedIn => SupabaseConfig.isLoggedIn;
  String? get _userId => SupabaseConfig.currentUser?.id;

  List<ExamModel> getAll() {
    final list = LocalStorageService.examBox.values.toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    return list;
  }

  List<ExamModel> upcoming() =>
      getAll().where((e) => !e.isPast).toList();

  Future<ExamModel> create({
    required String courseCode,
    required String courseName,
    required DateTime examDate,
    String? examTime,
    String? venue,
    String? notes,
    List<int> alertDaysBefore = const [7, 3, 1],
  }) async {
    final exam = ExamModel(
      id: _uuid.v4(),
      userId: _userId,
      courseCode: courseCode,
      courseName: courseName,
      examDate: examDate,
      examTime: examTime,
      venue: venue,
      notes: notes,
    );
    await LocalStorageService.examBox.put(exam.id, exam);
    await NotificationService.instance.scheduleExamAlerts(exam, alertDaysBefore);

    if (_isLoggedIn) await _push(exam);
    return exam;
  }

  Future<void> update(
    ExamModel exam, {
    List<int> alertDaysBefore = const [7, 3, 1],
  }) async {
    exam.isSynced = false;
    await exam.save();
    await NotificationService.instance.scheduleExamAlerts(exam, alertDaysBefore);
    if (_isLoggedIn) await _push(exam);
  }

  Future<void> delete(ExamModel exam) async {
    await NotificationService.instance.cancelExamAlerts(exam.id, 5);
    if (_isLoggedIn) {
      try {
        await SupabaseConfig.client.from('exams').delete().eq('id', exam.id);
      } catch (_) {}
    }
    await exam.delete();
  }

  Future<void> _push(ExamModel exam) async {
    if (_userId == null) return;
    try {
      await SupabaseConfig.client
          .from('exams')
          .upsert(exam.toSupabaseMap(userId: _userId!));
      exam.isSynced = true;
      await exam.save();
    } catch (_) {}
  }

  Future<void> pullFromSupabase({List<int> alertDaysBefore = const [7, 3, 1]}) async {
    if (!_isLoggedIn || _userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('exams')
          .select()
          .eq('user_id', _userId!);
      for (final row in rows as List) {
        final remote = ExamModel.fromSupabaseMap(row as Map<String, dynamic>);
        await LocalStorageService.examBox.put(remote.id, remote);
        await NotificationService.instance
            .scheduleExamAlerts(remote, alertDaysBefore);
      }
    } catch (_) {}
  }

  Future<void> migrateGuestDataToAccount(String userId) async {
    final unsynced = LocalStorageService.examBox.values
        .where((e) => e.userId == null || !e.isSynced)
        .toList();
    for (final exam in unsynced) {
      exam.userId = userId;
      await SupabaseConfig.client
          .from('exams')
          .upsert(exam.toSupabaseMap(userId: userId));
      exam.isSynced = true;
      await exam.save();
    }
  }
}
