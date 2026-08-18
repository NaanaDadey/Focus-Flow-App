import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/countdown_card.dart';
import '../../widgets/guest_banner.dart';
import '../../widgets/empty_state.dart';
import '../auth/login_screen.dart';
import '../tasks/add_edit_task_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final timetable = context.watch<TimetableProvider>();
    final semester = context.watch<SemesterProvider>();
    final scheme = Theme.of(context).colorScheme;

    final greeting = _greeting();
    final name = auth.profile?.fullName?.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              if (auth.isGuest) {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddEditTaskScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          taskProvider.refresh();
          timetable.refresh();
          semester.refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            Text('$greeting${name != null ? ', $name' : ''} 👋',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            if (auth.isGuest) ...[
              GuestBanner(
                onCreateAccount: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 16),
            ],
            _ProgressSummary(taskProvider: taskProvider),
            const SizedBox(height: 20),
            if (timetable.todayRemaining.isNotEmpty) ...[
              const _SectionHeader(title: 'Next up today'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.seed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${timetable.todayRemaining.first.courseCode} — ${timetable.todayRemaining.first.courseName}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${timetable.todayRemaining.first.startTime} - ${timetable.todayRemaining.first.endTime}'
                              '${timetable.todayRemaining.first.location != null ? ' • ${timetable.todayRemaining.first.location}' : ''}',
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (semester.nextExam != null) ...[
              const _SectionHeader(title: 'Next exam'),
              const SizedBox(height: 8),
              CountdownCard(exam: semester.nextExam!),
              const SizedBox(height: 20),
            ],
            _SectionHeader(
                title: "Today's tasks",
                trailing: '${taskProvider.dueToday.length}'),
            const SizedBox(height: 8),
            if (taskProvider.dueToday.isEmpty)
              const EmptyState(
                icon: Icons.beach_access_outlined,
                title: 'Nothing due today',
                message: 'Enjoy the breathing room — or get ahead on tomorrow.',
              )
            else
              ...taskProvider.dueToday.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskCard(
                      task: t,
                      onToggle: () => taskProvider.toggleComplete(t),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddEditTaskScreen(task: t))),
                      onDelete: () => taskProvider.deleteTask(t),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (trailing != null)
          Text(trailing!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final TaskProvider taskProvider;
  const _ProgressSummary({required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate = taskProvider.completionRate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                  ),
                  Text('${(rate * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall progress',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${taskProvider.completed.length} completed • ${taskProvider.pending.length} active'
                    '${taskProvider.overdue.isNotEmpty ? ' • ${taskProvider.overdue.length} overdue' : ''}',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
