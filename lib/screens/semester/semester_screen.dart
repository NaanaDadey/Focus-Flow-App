import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/semester_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/countdown_card.dart';
import 'add_course_screen.dart';
import 'add_exam_screen.dart';

/// "Semester" tab — the home for everything the abstract calls the
/// "semester outline": registered courses plus every upcoming exam, with
/// countdown cards that back the exam-reminder notifications scheduled
/// in [NotificationService].
class SemesterScreen extends StatefulWidget {
  const SemesterScreen({super.key});

  @override
  State<SemesterScreen> createState() => _SemesterScreenState();
}

class _SemesterScreenState extends State<SemesterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    if (_tabController.index == 0) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AddCourseScreen()));
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AddExamScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final semester = context.watch<SemesterProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Courses (${semester.courses.length})'),
            Tab(text: 'Exams (${semester.exams.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---- Courses (semester outline) --------------------------
          semester.courses.isEmpty
              ? const EmptyState(
                  icon: Icons.school_outlined,
                  title: 'No courses yet',
                  message: 'Add your semester outline so tasks and exams can\n'
                      'link back to the right course.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: semester.courses.length,
                  itemBuilder: (context, i) {
                    final c = semester.courses[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.seed.withValues(alpha: 0.15),
                            foregroundColor: AppTheme.seed,
                            child: Text(
                              c.courseCode.isNotEmpty ? c.courseCode[0] : '?',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${c.courseCode} — ${c.courseName}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${c.creditHours.toStringAsFixed(0)} credit hour(s)'
                            '${c.instructor != null ? ' • ${c.instructor}' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => context
                                .read<SemesterProvider>()
                                .deleteCourse(c),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          // ---- Exams --------------------------------------------------
          semester.exams.isEmpty
              ? const EmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'No exams scheduled',
                  message: 'Add exam dates from your semester outline and\n'
                      "we'll count down and remind you automatically.",
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: semester.exams.length,
                  itemBuilder: (context, i) {
                    final e = semester.exams[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CountdownCard(
                        exam: e,
                        onDelete: () =>
                            context.read<SemesterProvider>().deleteExam(e),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
