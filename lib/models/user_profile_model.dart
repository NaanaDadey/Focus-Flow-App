/// A signed-in user's profile + preference settings.
/// This always lives in Supabase — there's no guest-mode equivalent
/// since a profile only exists once someone creates an account.
class UserProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? institution;
  final String? program;
  final String? avatarUrl;
  final List<String> reminderTimes; // ['08:00','13:00','19:00']
  final bool dailyRemindersEnabled;
  final List<int> examAlertDaysBefore; // [7, 3, 1]

  const UserProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.institution,
    this.program,
    this.avatarUrl,
    this.reminderTimes = const ['08:00', '13:00', '19:00'],
    this.dailyRemindersEnabled = true,
    this.examAlertDaysBefore = const [7, 3, 1],
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      institution: map['institution'] as String?,
      program: map['program'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      reminderTimes: (map['reminder_times'] as List?)?.cast<String>() ??
          const ['08:00', '13:00', '19:00'],
      dailyRemindersEnabled: map['daily_reminders_enabled'] as bool? ?? true,
      examAlertDaysBefore:
          (map['exam_alert_days_before'] as List?)?.cast<int>() ??
              const [7, 3, 1],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'institution': institution,
      'program': program,
      'avatar_url': avatarUrl,
      'reminder_times': reminderTimes,
      'daily_reminders_enabled': dailyRemindersEnabled,
      'exam_alert_days_before': examAlertDaysBefore,
    };
  }

  UserProfileModel copyWith({
    String? fullName,
    String? institution,
    String? program,
    String? avatarUrl,
    List<String>? reminderTimes,
    bool? dailyRemindersEnabled,
    List<int>? examAlertDaysBefore,
  }) {
    return UserProfileModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      institution: institution ?? this.institution,
      program: program ?? this.program,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      dailyRemindersEnabled:
          dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      examAlertDaysBefore: examAlertDaysBefore ?? this.examAlertDaysBefore,
    );
  }
}
