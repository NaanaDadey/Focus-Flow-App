/// App-wide constants. Keep magic strings/numbers centralized here so the
/// rest of the codebase stays readable and easy to tweak for a demo.
library;

class AppConstants {
  AppConstants._();

  static const String appName = 'FocusFlow';
  static const String tagline = 'Beat procrastination. Own your schedule.';

  // ---- Supabase ---------------------------------------------------------
  // Replace these with your own project's values before running the app.
  // Get them from: Supabase Dashboard → Project Settings → API
  static const String supabaseUrl = 'https://qqzrdkhasjdlefzqudcj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxenJka2hhc2pkbGVmenF1ZGNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyMDA2ODgsImV4cCI6MjEwMTc3NjY4OH0.m1myEaVejPO-snBZLud1tJIlJhMrOcapez7u9Vsxw9Q';

  // ---- Hive box names (local/guest storage) ------------------------------
  static const String taskBox = 'tasks_box';
  static const String timetableBox = 'timetable_box';
  static const String examBox = 'exam_box';
  static const String courseBox = 'course_box';
  static const String settingsBox = 'settings_box';

  // ---- Notification channel ---------------------------------------------
  static const String reminderChannelId = 'focusflow_reminders';
  static const String reminderChannelName = 'Task & Exam Reminders';
  static const String reminderChannelDesc =
      'Daily nudges and exam countdown alerts from FocusFlow';

  // ---- Misc ---------------------------------------------------------------
  static const List<String> taskCategories = [
    'general',
    'assignment',
    'project',
    'reading',
    'personal',
  ];

  static const List<String> taskPriorities = [
    'low',
    'medium',
    'high',
    'urgent'
  ];

  /// Default 3x-daily digest reminder times, matching the project
  /// abstract's "reminders three times a day" requirement.
  static const List<String> reminderDefaults = ['08:00', '13:00', '19:00'];

  static const List<String> weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}
