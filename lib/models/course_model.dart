import 'package:hive/hive.dart';

part 'course_model.g.dart';

/// A course the student is registered for this semester.
@HiveType(typeId: 2)
class CourseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String? semesterId;

  @HiveField(3)
  String courseCode;

  @HiveField(4)
  String courseName;

  @HiveField(5)
  double creditHours;

  @HiveField(6)
  String? instructor;

  @HiveField(7)
  bool isSynced;

  CourseModel({
    required this.id,
    this.userId,
    this.semesterId,
    required this.courseCode,
    required this.courseName,
    this.creditHours = 3,
    this.instructor,
    this.isSynced = false,
  });

  factory CourseModel.fromSupabaseMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      semesterId: map['semester_id'] as String?,
      courseCode: map['course_code'] as String,
      courseName: map['course_name'] as String,
      creditHours: (map['credit_hours'] as num?)?.toDouble() ?? 3,
      instructor: map['instructor'] as String?,
      isSynced: true,
    );
  }

  Map<String, dynamic> toSupabaseMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'semester_id': semesterId,
      'course_code': courseCode,
      'course_name': courseName,
      'credit_hours': creditHours,
      'instructor': instructor,
    };
  }
}
