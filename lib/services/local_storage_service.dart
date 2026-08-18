import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../models/timetable_entry_model.dart';
import '../models/course_model.dart';
import '../models/exam_model.dart';

/// Boots Hive and opens every box the app needs. Called once from `main()`
/// before `runApp`. Guest users store everything here; signed-in users use
/// the same boxes as an offline cache that [SyncService] reconciles with
/// Supabase.
class LocalStorageService {
  LocalStorageService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(TimetableEntryModelAdapter());
    Hive.registerAdapter(CourseModelAdapter());
    Hive.registerAdapter(ExamModelAdapter());

    await Future.wait([
      Hive.openBox<TaskModel>(AppConstants.taskBox),
      Hive.openBox<TimetableEntryModel>(AppConstants.timetableBox),
      Hive.openBox<CourseModel>(AppConstants.courseBox),
      Hive.openBox<ExamModel>(AppConstants.examBox),
      Hive.openBox(AppConstants.settingsBox),
    ]);

    _initialized = true;
  }

  static Box<TaskModel> get taskBox => Hive.box<TaskModel>(AppConstants.taskBox);

  static Box<TimetableEntryModel> get timetableBox =>
      Hive.box<TimetableEntryModel>(AppConstants.timetableBox);

  static Box<CourseModel> get courseBox =>
      Hive.box<CourseModel>(AppConstants.courseBox);

  static Box<ExamModel> get examBox => Hive.box<ExamModel>(AppConstants.examBox);

  static Box get settingsBox => Hive.box(AppConstants.settingsBox);

  /// Wipes all local data. Called on sign-out if the user chooses not to
  /// keep an offline copy, and after a successful post-signup migration.
  static Future<void> clearAll() async {
    await Future.wait([
      taskBox.clear(),
      timetableBox.clear(),
      courseBox.clear(),
      examBox.clear(),
    ]);
  }
}
