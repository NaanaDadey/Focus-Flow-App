import 'package:hive/hive.dart';

part 'task_model.g.dart';

/// A student task/assignment with a deadline.
///
/// This model is deliberately storage-agnostic: the same object is used
/// whether it lives in a local Hive box (guest mode) or was fetched from
/// Supabase (signed-in mode). [toSupabaseMap] / [fromSupabaseMap] and
/// the generated Hive adapter (`toJson`-free, field-based) let the
/// repository layer translate freely between the two.
@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? userId; // null while in guest/local-only mode

  @HiveField(2)
  String title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String category; // general, assignment, project, reading, personal

  @HiveField(5)
  String priority; // low, medium, high, urgent

  @HiveField(6)
  String status; // pending, in_progress, completed, missed

  @HiveField(7)
  DateTime deadline;

  @HiveField(8)
  DateTime? suggestedStart;

  @HiveField(9)
  int estimatedMinutes;

  @HiveField(10)
  int? actualMinutes;

  @HiveField(11)
  String? courseCode;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  @HiveField(14)
  DateTime? completedAt;

  /// True once this local record has been pushed to Supabase — used by
  /// the sync service to avoid re-uploading unchanged rows.
  @HiveField(15)
  bool isSynced;

  TaskModel({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.category = 'general',
    this.priority = 'medium',
    this.status = 'pending',
    required this.deadline,
    this.suggestedStart,
    this.estimatedMinutes = 60,
    this.actualMinutes,
    this.courseCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOverdue =>
      status != 'completed' && deadline.isBefore(DateTime.now());

  bool get isCompleted => status == 'completed';

  Duration get timeRemaining => deadline.difference(DateTime.now());

  factory TaskModel.fromSupabaseMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'medium',
      status: map['status'] as String? ?? 'pending',
      deadline: DateTime.parse(map['deadline'] as String),
      suggestedStart: map['suggested_start'] != null
          ? DateTime.parse(map['suggested_start'] as String)
          : null,
      estimatedMinutes: map['estimated_minutes'] as int? ?? 60,
      actualMinutes: map['actual_minutes'] as int?,
      courseCode: map['course_code'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      isSynced: true,
    );
  }

  Map<String, dynamic> toSupabaseMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'deadline': deadline.toUtc().toIso8601String(),
      'suggested_start': suggestedStart?.toUtc().toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'actual_minutes': actualMinutes,
      'course_code': courseCode,
      'completed_at': completedAt?.toUtc().toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? deadline,
    DateTime? suggestedStart,
    int? estimatedMinutes,
    int? actualMinutes,
    String? courseCode,
    DateTime? completedAt,
    bool? isSynced,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      suggestedStart: suggestedStart ?? this.suggestedStart,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      courseCode: courseCode ?? this.courseCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
