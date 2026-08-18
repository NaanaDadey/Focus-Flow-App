import 'package:uuid/uuid.dart';
import '../core/supabase_config.dart';
import '../models/timetable_entry_model.dart';
import 'local_storage_service.dart';

/// Local-first data layer for the weekly recurring class timetable.
/// See [TaskRepository] for the general local-first + sync pattern.
class TimetableRepository {
  final _uuid = const Uuid();

  bool get _isLoggedIn => SupabaseConfig.isLoggedIn;
  String? get _userId => SupabaseConfig.currentUser?.id;

  List<TimetableEntryModel> getAll() {
    final list = LocalStorageService.timetableBox.values.toList();
    list.sort((a, b) {
      final dayCmp = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (dayCmp != 0) return dayCmp;
      return a.startTime.compareTo(b.startTime);
    });
    return list;
  }

  List<TimetableEntryModel> forDay(int dayOfWeek) =>
      getAll().where((e) => e.dayOfWeek == dayOfWeek).toList();

  Future<TimetableEntryModel> create({
    required String courseCode,
    required String courseName,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? location,
    String colorHex = '#6C63FF',
  }) async {
    final entry = TimetableEntryModel(
      id: _uuid.v4(),
      userId: _userId,
      courseCode: courseCode,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: location,
      colorHex: colorHex,
    );
    await LocalStorageService.timetableBox.put(entry.id, entry);
    if (_isLoggedIn) await _push(entry);
    return entry;
  }

  Future<void> update(TimetableEntryModel entry) async {
    entry.isSynced = false;
    await entry.save();
    if (_isLoggedIn) await _push(entry);
  }

  Future<void> delete(TimetableEntryModel entry) async {
    if (_isLoggedIn) {
      try {
        await SupabaseConfig.client
            .from('timetable_entries')
            .delete()
            .eq('id', entry.id);
      } catch (_) {}
    }
    await entry.delete();
  }

  Future<void> _push(TimetableEntryModel entry) async {
    if (_userId == null) return;
    try {
      await SupabaseConfig.client
          .from('timetable_entries')
          .upsert(entry.toSupabaseMap(userId: _userId!));
      entry.isSynced = true;
      await entry.save();
    } catch (_) {}
  }

  Future<void> pullFromSupabase() async {
    if (!_isLoggedIn || _userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('timetable_entries')
          .select()
          .eq('user_id', _userId!);
      for (final row in rows as List) {
        final remote =
            TimetableEntryModel.fromSupabaseMap(row as Map<String, dynamic>);
        await LocalStorageService.timetableBox.put(remote.id, remote);
      }
    } catch (_) {}
  }

  Future<void> migrateGuestDataToAccount(String userId) async {
    final unsynced = LocalStorageService.timetableBox.values
        .where((e) => e.userId == null || !e.isSynced)
        .toList();
    for (final entry in unsynced) {
      entry.userId = userId;
      await SupabaseConfig.client
          .from('timetable_entries')
          .upsert(entry.toSupabaseMap(userId: userId));
      entry.isSynced = true;
      await entry.save();
    }
  }
}
