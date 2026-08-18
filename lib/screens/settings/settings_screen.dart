import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/semester_provider.dart';
import '../../services/notification_service.dart';
import '../../services/local_storage_service.dart';
import '../auth/login_screen.dart';

/// Settings tab — reachable without an account (theme + reminder times
/// are stored in Hive locally for guests) and gains profile fields and
/// cross-device sync once signed in.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _AccountCard(auth: auth),
          const SizedBox(height: 20),
          const _SectionLabel('Reminders'),
          const SizedBox(height: 8),
          const _ReminderTimesCard(),
          const SizedBox(height: 12),
          const _ExamAlertsCard(),
          const SizedBox(height: 20),
          const _SectionLabel('Appearance'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System default'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.mode,
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.mode,
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.mode,
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (auth.isAuthenticated)
            OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Signed out. Your data stays on this device.')),
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.danger),
              label: const Text('Sign out',
                  style: TextStyle(color: AppTheme.danger)),
            ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConstants.appName} • v1.0.0\nFinal-year project build',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));
  }
}

class _AccountCard extends StatelessWidget {
  final AuthProvider auth;
  const _AccountCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (auth.isGuest) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person_outline, color: scheme.onPrimaryContainer),
          ),
          title: const Text('Browsing as guest', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Create a free account to sync across devices.'),
          trailing: FilledButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Sign in'),
          ),
        ),
      );
    }
    final profile = auth.profile;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.seed,
          child: Text(
            (profile?.fullName?.isNotEmpty == true
                    ? profile!.fullName!
                    : profile?.email ?? '?')[0]
                .toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(profile?.fullName ?? 'Student',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(profile?.email ?? ''),
      ),
    );
  }
}

/// Lets the user customize the 3x-daily digest reminder times that back
/// the abstract's "reminders three times a day" requirement — defaults
/// to 08:00 / 13:00 / 19:00 but is fully editable.
class _ReminderTimesCard extends StatefulWidget {
  const _ReminderTimesCard();
  @override
  State<_ReminderTimesCard> createState() => _ReminderTimesCardState();
}

class _ReminderTimesCardState extends State<_ReminderTimesCard> {
  static const _guestTimesKey = 'guest_reminder_times';
  static const _guestEnabledKey = 'guest_reminders_enabled';

  /// Guests have no Supabase profile row to store this in, so it's kept
  /// in the local settings box instead — same box [ThemeProvider] uses.
  List<String> _guestTimes() {
    final saved =
        LocalStorageService.settingsBox.get(_guestTimesKey) as List?;
    return saved?.cast<String>() ?? AppConstants.reminderDefaults;
  }

  bool _guestEnabled() =>
      LocalStorageService.settingsBox.get(_guestEnabledKey) as bool? ?? true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final times =
        auth.profile?.reminderTimes ?? (auth.isGuest ? _guestTimes() : AppConstants.reminderDefaults);
    final enabled =
        auth.profile?.dailyRemindersEnabled ?? (auth.isGuest ? _guestEnabled() : true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily check-in reminders'),
              subtitle: const Text("What's due today, nudged straight to your phone."),
              value: enabled,
              onChanged: auth.isAuthenticated
                  ? (v) async {
                      final updated =
                          auth.profile!.copyWith(dailyRemindersEnabled: v);
                      await auth.updateProfile(updated);
                      if (v) {
                        await NotificationService.instance
                            .scheduleDailyReminders(updated.reminderTimes);
                      } else {
                        await NotificationService.instance.cancelDailyReminders();
                      }
                    }
                  : (v) async {
                      await LocalStorageService.settingsBox
                          .put(_guestEnabledKey, v);
                      if (v) {
                        await NotificationService.instance
                            .scheduleDailyReminders(times);
                      } else {
                        await NotificationService.instance.cancelDailyReminders();
                      }
                      setState(() {});
                    },
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in times)
                  Chip(
                    label: Text(t),
                    onDeleted: times.length > 1
                        ? () => _updateTimes(context, auth,
                            [...times]..remove(t))
                        : null,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Add time'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (picked == null) return;
                    final hhmm =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    if (!times.contains(hhmm)) {
                      _updateTimes(context, auth, [...times, hhmm]..sort());
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTimes(
      BuildContext context, AuthProvider auth, List<String> newTimes) async {
    if (auth.isAuthenticated) {
      await auth.updateProfile(auth.profile!.copyWith(reminderTimes: newTimes));
    } else {
      await LocalStorageService.settingsBox.put(_guestTimesKey, newTimes);
    }
    await NotificationService.instance.scheduleDailyReminders(newTimes);
    if (mounted) setState(() {});
  }
}

/// Lets the user pick how many days before an exam they get warned
/// (default 7 / 3 / 1) — reschedules every existing exam's alerts on
/// change so the new lead times take effect immediately.
class _ExamAlertsCard extends StatefulWidget {
  const _ExamAlertsCard();
  @override
  State<_ExamAlertsCard> createState() => _ExamAlertsCardState();
}

class _ExamAlertsCardState extends State<_ExamAlertsCard> {
  static const _options = [14, 7, 5, 3, 2, 1];

  @override
  Widget build(BuildContext context) {
    final semester = context.watch<SemesterProvider>();
    final selected = semester.alertDaysBefore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exam countdown alerts',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Get warned this many days before each exam.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _options.map((d) {
                final isSelected = selected.contains(d);
                return FilterChip(
                  label: Text('${d}d'),
                  selected: isSelected,
                  onSelected: (v) {
                    final updated = [...selected];
                    if (v) {
                      updated.add(d);
                    } else {
                      updated.remove(d);
                    }
                    updated.sort((a, b) => b.compareTo(a));
                    semester.setAlertDaysBefore(updated);
                    for (final exam in semester.exams) {
                      NotificationService.instance
                          .scheduleExamAlerts(exam, semester.alertDaysBefore);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
