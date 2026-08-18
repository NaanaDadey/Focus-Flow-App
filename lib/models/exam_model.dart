import 'package:hive/hive.dart';

part 'exam_model.g.dart';

@HiveType(typeId: 3)
class ExamModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String courseCode;

  @HiveField(3)
  String courseName;

  @HiveField(4)
  DateTime examDate;

  @HiveField(5)
  String? examTime; // 'HH:mm', nullable if TBA

  @HiveField(6)
  String? venue;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  bool isSynced;

  ExamModel({
    required this.id,
    this.userId,
    required this.courseCode,
    required this.courseName,
    required this.examDate,
    this.examTime,
    this.venue,
    this.notes,
    this.isSynced = false,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exam = DateTime(examDate.year, examDate.month, examDate.day);
    return exam.difference(today).inDays;
  }

  bool get isPast => daysRemaining < 0;
  bool get isToday => daysRemaining == 0;

  factory ExamModel.fromSupabaseMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      courseCode: map['course_code'] as String,
      courseName: map['course_name'] as String,
      examDate: DateTime.parse(map['exam_date'] as String),
      examTime: map['exam_time'] as String?,
      venue: map['venue'] as String?,
      notes: map['notes'] as String?,
      isSynced: true,
    );
  }

  Map<String, dynamic> toSupabaseMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'course_code': courseCode,
      'course_name': courseName,
      'exam_date':
          '${examDate.year.toString().padLeft(4, '0')}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}',
      'exam_time': examTime,
      'venue': venue,
      'notes': notes,
    };
  }
}
