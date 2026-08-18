import 'package:uuid/uuid.dart';
import '../core/supabase_config.dart';
import '../models/course_model.dart';
import 'local_storage_service.dart';

/// Local-first data layer for a semester's course list.
/// See [TaskRepository] for the general local-first + sync pattern.
class CourseRepository {
  final _uuid = const Uuid();

  bool get _isLoggedIn => SupabaseConfig.isLoggedIn;
  String? get _userId => SupabaseConfig.currentUser?.id;

  List<CourseModel> getAll() =>
      LocalStorageService.courseBox.values.toList()
        ..sort((a, b) => a.courseCode.compareTo(b.courseCode));

  Future<CourseModel> create({
    required String courseCode,
    required String courseName,
    double creditHours = 3,
    String? instructor,
    String? semesterId,
  }) async {
    final course = CourseModel(
      id: _uuid.v4(),
      userId: _userId,
      semesterId: semesterId,
      courseCode: courseCode,
      courseName: courseName,
      creditHours: creditHours,
      instructor: instructor,
    );
    await LocalStorageService.courseBox.put(course.id, course);
    if (_isLoggedIn) await _push(course);
    return course;
  }

  Future<void> update(CourseModel course) async {
    course.isSynced = false;
    await course.save();
    if (_isLoggedIn) await _push(course);
  }

  Future<void> delete(CourseModel course) async {
    if (_isLoggedIn) {
      try {
        await SupabaseConfig.client
            .from('courses')
            .delete()
            .eq('id', course.id);
      } catch (_) {}
    }
    await course.delete();
  }

  Future<void> _push(CourseModel course) async {
    if (_userId == null) return;
    try {
      await SupabaseConfig.client
          .from('courses')
          .upsert(course.toSupabaseMap(userId: _userId!));
      course.isSynced = true;
      await course.save();
    } catch (_) {}
  }

  Future<void> pullFromSupabase() async {
    if (!_isLoggedIn || _userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('courses')
          .select()
          .eq('user_id', _userId!);
      for (final row in rows as List) {
        final remote = CourseModel.fromSupabaseMap(row as Map<String, dynamic>);
        await LocalStorageService.courseBox.put(remote.id, remote);
      }
    } catch (_) {}
  }

  Future<void> migrateGuestDataToAccount(String userId) async {
    final unsynced = LocalStorageService.courseBox.values
        .where((c) => c.userId == null || !c.isSynced)
        .toList();
    for (final course in unsynced) {
      course.userId = userId;
      await SupabaseConfig.client
          .from('courses')
          .upsert(course.toSupabaseMap(userId: userId));
      course.isSynced = true;
      await course.save();
    }
  }
}
