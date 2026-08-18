import 'package:flutter/foundation.dart';
import '../models/course_model.dart';
import '../models/exam_model.dart';
import '../services/course_repository.dart';
import '../services/exam_repository.dart';

/// Combines courses (semester outline) and exams into one provider since
/// they're always viewed together in the "Semester" tab.
class SemesterProvider extends ChangeNotifier {
  final CourseRepository _courseRepo;
  final ExamRepository _examRepo;

  SemesterProvider({CourseRepository? courseRepo, ExamRepository? examRepo})
      : _courseRepo = courseRepo ?? CourseRepository(),
        _examRepo = examRepo ?? ExamRepository() {
    refresh();
  }

  List<CourseModel> _courses = [];
  List<ExamModel> _exams = [];
  List<int> _alertDaysBefore = const [7, 3, 1];

  List<CourseModel> get courses => _courses;
  List<ExamModel> get exams => _exams;
  List<ExamModel> get upcomingExams => _examRepo.upcoming();
  List<int> get alertDaysBefore => _alertDaysBefore;

  ExamModel? get nextExam =>
      upcomingExams.isEmpty ? null : upcomingExams.first;

  /// Updates the exam-countdown lead times (e.g. [7,3,1] days before).
  /// Callers are still responsible for re-scheduling each exam's alerts
  /// via [NotificationService] after calling this.
  void setAlertDaysBefore(List<int> days) {
    _alertDaysBefore = days.isEmpty ? [1] : days;
    notifyListeners();
  }

  void refresh() {
    _courses = _courseRepo.getAll();
    _exams = _examRepo.getAll();
    notifyListeners();
  }

  Future<void> addCourse({
    required String courseCode,
    required String courseName,
    double creditHours = 3,
    String? instructor,
  }) async {
    await _courseRepo.create(
      courseCode: courseCode,
      courseName: courseName,
      creditHours: creditHours,
      instructor: instructor,
    );
    refresh();
  }

  Future<void> deleteCourse(CourseModel course) async {
    await _courseRepo.delete(course);
    refresh();
  }

  Future<void> addExam({
    required String courseCode,
    required String courseName,
    required DateTime examDate,
    String? examTime,
    String? venue,
    String? notes,
  }) async {
    await _examRepo.create(
      courseCode: courseCode,
      courseName: courseName,
      examDate: examDate,
      examTime: examTime,
      venue: venue,
      notes: notes,
      alertDaysBefore: alertDaysBefore,
    );
    refresh();
  }

  Future<void> deleteExam(ExamModel exam) async {
    await _examRepo.delete(exam);
    refresh();
  }
}
