import 'package:flutter/foundation.dart';
import '../models/timetable_entry_model.dart';
import '../services/timetable_repository.dart';

class TimetableProvider extends ChangeNotifier {
  final TimetableRepository _repo;
  TimetableProvider({TimetableRepository? repo})
      : _repo = repo ?? TimetableRepository() {
    refresh();
  }

  List<TimetableEntryModel> _entries = [];
  List<TimetableEntryModel> get entries => _entries;

  List<TimetableEntryModel> forDay(int dayOfWeek) =>
      _entries.where((e) => e.dayOfWeek == dayOfWeek).toList();

  /// Today's remaining classes, soonest first — powers the dashboard's
  /// "next up" card.
  List<TimetableEntryModel> get todayRemaining {
    final now = DateTime.now();
    final today = forDay(now.weekday);
    final nowMinutes = now.hour * 60 + now.minute;
    return today.where((e) {
      final parts = e.startTime.split(':');
      final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      return startMinutes >= nowMinutes;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void refresh() {
    _entries = _repo.getAll();
    notifyListeners();
  }

  Future<void> addEntry({
    required String courseCode,
    required String courseName,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? location,
    String colorHex = '#6C63FF',
  }) async {
    await _repo.create(
      courseCode: courseCode,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: location,
      colorHex: colorHex,
    );
    refresh();
  }

  Future<void> updateEntry(TimetableEntryModel entry) async {
    await _repo.update(entry);
    refresh();
  }

  Future<void> deleteEntry(TimetableEntryModel entry) async {
    await _repo.delete(entry);
    refresh();
  }
}
