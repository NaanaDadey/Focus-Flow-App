import 'package:hive/hive.dart';

part 'timetable_entry_model.g.dart';

/// One recurring weekly class slot, e.g. "CSC401 Software Eng, Mon 10:00-12:00".
@HiveType(typeId: 1)
class TimetableEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String courseCode;

  @HiveField(3)
  String courseName;

  /// 1 = Monday ... 7 = Sunday (ISO-8601 weekday numbering)
  @HiveField(4)
  int dayOfWeek;

  @HiveField(5)
  String startTime; // 'HH:mm'

  @HiveField(6)
  String endTime; // 'HH:mm'

  @HiveField(7)
  String? location;

  @HiveField(8)
  String colorHex;

  @HiveField(9)
  bool isSynced;

  TimetableEntryModel({
    required this.id,
    this.userId,
    required this.courseCode,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    this.colorHex = '#6C63FF',
    this.isSynced = false,
  });

  factory TimetableEntryModel.fromSupabaseMap(Map<String, dynamic> map) {
    return TimetableEntryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      courseCode: map['course_code'] as String,
      courseName: map['course_name'] as String,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      location: map['location'] as String?,
      colorHex: map['color_hex'] as String? ?? '#6C63FF',
      isSynced: true,
    );
  }

  Map<String, dynamic> toSupabaseMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'course_code': courseCode,
      'course_name': courseName,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'color_hex': colorHex,
    };
  }
}
